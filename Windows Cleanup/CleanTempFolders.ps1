# Define path to the temporary folder for the current user account
$userTempPath = "C:\Users\<accountusernamehere>\AppData\Local\Temp"

# Define path to the system-wide temporary folder
$systemTempPath = "C:\Windows\Temp"

# Function to clean a specified temporary folder
function Clean-TempFolder {
    param (
        [string]$Path  # Path to the temporary folder to be cleaned
    )

    # Delete files in the specified path, including subdirectories
    # '-Force' is used to include hidden and system files
    $files = Get-ChildItem -Path $Path -File -Recurse -Force
    foreach ($file in $files) {
        try {
            # Attempt to delete each file
            # '-ErrorAction Stop' makes the script stop on errors
            # '-Confirm:$false' suppresses confirmation prompts
            Remove-Item $file.FullName -Force -ErrorAction Stop -Confirm:$false
        } catch {
            # Log an error message if file deletion fails
            Write-Error "Failed to delete file: $($_.Exception.Message)"
        }
    }

    # Delete directories in the specified path, including subdirectories
    $directories = Get-ChildItem -Path $Path -Directory -Recurse -Force
    foreach ($dir in $directories) {
        try {
            # Attempt to delete each directory
            Remove-Item $dir.FullName -Force -Recurse -ErrorAction Stop -Confirm:$false
        } catch {
            # Log an error message if directory deletion fails
            Write-Error "Failed to delete directory: $($_.Exception.Message)"
        }
    }
}

# Output message indicating start of cleanup for user TEMP folder
Write-Output "Cleaning user TEMP folder..."
# Call the function to clean the user TEMP folder
Clean-TempFolder -Path $userTempPath

# Output message indicating start of cleanup for system TEMP folder
Write-Output "Cleaning system TEMP folder..."
# Call the function to clean the system TEMP folder
Clean-TempFolder -Path $systemTempPath

# Output message indicating completion of TEMP folders cleanup
Write-Output "TEMP folders cleanup completed."
