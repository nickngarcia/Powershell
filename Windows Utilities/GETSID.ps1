# Lists all local accounts, including groups, with their SIDs
Get-CimInstance Win32_Account | Select-Object Name, SID, Caption