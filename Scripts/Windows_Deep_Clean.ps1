<# 
 Windows 11 LTSC – System Cleanup
 Save as: Cleanup-Win11LTSC.ps1
 Run: Right-click > Run with PowerShell (as Administrator)

 Default: cleans temp/cache + recycle bin.
 Optional: -DeepComponentCleanup does DISM StartComponentCleanup (irreversible). 
#>

[CmdletBinding()]
param(
    [switch]$DeepComponentCleanup
)

#--- Helpers ---------------------------------------------------------------#
function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Error "Please run this script as Administrator."
        exit 1
    }
}

function Get-DirSize([string]$Path) {
    if (-not (Test-Path $Path)) { return 0 }
    try {
        (Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
    } catch { 0 }
}

function Remove-PathContents([string]$Path) {
    if (-not (Test-Path $Path)) { return 0 }
    $before = Get-DirSize $Path
    try {
        Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Could not fully clean: $Path ($($_.Exception.Message))"
    }
    $after = Get-DirSize $Path
    [Math]::Max($before - $after, 0)
}

function Format-Bytes([long]$bytes) {
    switch ($bytes) {
        {$_ -ge 1GB} { '{0:N2} GB' -f ($bytes/1GB); break }
        {$_ -ge 1MB} { '{0:N2} MB' -f ($bytes/1MB); break }
        {$_ -ge 1KB} { '{0:N2} KB' -f ($bytes/1KB); break }
        default { "$bytes B" }
    }
}

#--- Start ----------------------------------------------------------------#
Assert-Admin
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$freedTotal = 0
$freed = @{}

Write-Host "Starting system cleanup..." -ForegroundColor Cyan

# 1) User + System temp
$freed['User TEMP']   = Remove-PathContents $env:TEMP
$freed['Windows Temp'] = Remove-PathContents "$env:WINDIR\Temp"

# 2) Recycle Bin (all drives)
try {
    $rbBefore = 0
    try {
        $rbBefore = (Get-ChildItem 'RecycleBin::\' -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
    } catch { $rbBefore = 0 }
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue | Out-Null
    $freed['Recycle Bin'] = $rbBefore
    Write-Host "Recycle Bin cleared." -ForegroundColor Green
} catch {
    Write-Warning "Failed to clear Recycle Bin: $($_.Exception.Message)"
}

# 3) Windows Update download cache
try {
    Write-Host "Stopping Windows Update service..." -ForegroundColor DarkGray
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue
    $freed['WU Download'] = Remove-PathContents "$env:WINDIR\SoftwareDistribution\Download"
} finally {
    Start-Service bits -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

# 4) Delivery Optimization cache
try {
    Stop-Service DoSvc -Force -ErrorAction SilentlyContinue
    $freed['Delivery Optimization'] = Remove-PathContents "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
} finally {
    Start-Service DoSvc -ErrorAction SilentlyContinue
}

# 5) Prefetch
$freed['Prefetch'] = Remove-PathContents "$env:WINDIR\Prefetch"

# 6) Windows Error Reporting queues/archives
$freed['WER Queue']    = Remove-PathContents "$env:ProgramData\Microsoft\Windows\WER\ReportQueue"
$freed['WER Archive']  = Remove-PathContents "$env:ProgramData\Microsoft\Windows\WER\ReportArchive"

# 7) CBS logs (keep current log; clear large archives)
$CBS = "$env:WINDIR\Logs\CBS"
if (Test-Path "$CBS\CBS.log") {
    try {
        # Rotate the current log so we can clear old ones safely
        Copy-Item "$CBS\CBS.log" "$CBS\CBS_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" -ErrorAction SilentlyContinue
        Clear-Content "$CBS\CBS.log" -ErrorAction SilentlyContinue
    } catch { }
}
$freed['CBS Old Logs'] = (Get-ChildItem "$CBS\*.cab","$CBS\*.old","$CBS\*.persist.log" -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum
Get-ChildItem "$CBS\*.cab","$CBS\*.old","$CBS\*.persist.log" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

# 8) Temp crash dumps (if any)
$freed['MiniDumps'] = Remove-PathContents "$env:WINDIR\Minidump"

# Optional 9) Deep Windows Component Cleanup (DISM)
if ($DeepComponentCleanup) {
    Write-Host "Running DISM StartComponentCleanup (this can take a while and is irreversible)..." -ForegroundColor Yellow
    try {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Null
        # We can't easily measure space per-component, so just re-analyze WinSxS for delta
        $winsxs = "$env:WINDIR\WinSxS"
        $before = Get-DirSize $winsxs
        # ResetBase is most aggressive; comment out if you want to keep uninstall ability:
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
        $after  = Get-DirSize $winsxs
        $delta = [Math]::Max($before - $after, 0)
        $freed['Component Store (DISM)'] = $delta
    } catch {
        Write-Warning "DISM cleanup failed: $($_.Exception.Message)"
    }
}

#--- Report ----------------------------------------------------------------#
$freed.Keys | ForEach-Object { $freedTotal += [int64]$freed[$_] }

Write-Host "`nCleanup summary:" -ForegroundColor Cyan
$freed.GetEnumerator() | Sort-Object Name | ForEach-Object {
    "{0,-28} {1,12}" -f ($_.Key + ":"), (Format-Bytes $_.Value)
}
"{0,-28} {1,12}" -f "TOTAL FREED:", (Format-Bytes $freedTotal) | Write-Host -ForegroundColor Green

$stopwatch.Stop()
Write-Host ("Elapsed time: {0:mm\:ss}" -f $stopwatch.Elapsed) -ForegroundColor DarkGray
Write-Host "Done." -ForegroundColor Cyan
