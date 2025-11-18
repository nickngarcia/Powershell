# ⭐ PowerShell Utility Scripts

A curated collection of PowerShell scripts for Windows cleanup, maintenance, automation, and general system administration.

---

## 📝 About This Repository

This repository contains useful PowerShell scripts I’ve created for Windows maintenance, cleanup tasks, diagnostics, and automation. The goal is to provide simple, reliable, and easy-to-follow scripts that help streamline repetitive tasks and improve system performance.

Over time, this repo will grow to include additional categories of scripts beyond cleanup — including system info, security hardening, and general automation tools.

---

## 📂 Repository Structure

~~~text
.
├── LICENSE
├── README.md
└── Windows Cleanup/
    ├── Windows_Deep_Clean.ps1
    └── CleanTempFolders.ps1
~~~

> Note: The folder is named `Windows Cleanup` (with a space).

---

## 📚 Table of Contents

- [About This Repository](#-about-this-repository)  
- [Repository Structure](#-repository-structure)  
- [Script Categories](#-script-categories)  
  - [Windows Cleanup](#windows-cleanup)  
- [Usage](#-usage)  
- [Requirements](#-requirements)  
- [Disclaimer](#-disclaimer)  
- [Contributing](#-contributing)  
- [Author](#-author)  

---

## 🛠 Script Categories

### Windows Cleanup

Scripts designed to improve Windows performance by removing unnecessary files and performing routine maintenance.

#### `Windows_Deep_Clean.ps1`

Deep cleanup script designed primarily for Windows 11 LTSC, but generally applicable to modern Windows versions.

**Features:**

- Asserts the script is running as Administrator.  
- Cleans:
  - User TEMP (`$env:TEMP`)
  - Windows TEMP (`C:\Windows\Temp`)
  - Recycle Bin (all drives)
  - Windows Update download cache (`SoftwareDistribution\Download`)
  - Delivery Optimization cache
  - Prefetch
  - Windows Error Reporting queues/archives
  - CBS log archives and CABs
  - MiniDump folder  
- Tracks how much space is freed per area and prints a summary with a total.  
- Optional **deep component cleanup** via DISM:

  - `-DeepComponentCleanup` switch runs:
    - `Dism.exe /Online /Cleanup-Image /StartComponentCleanup`
    - `Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase`  
  - Attempts to measure space reclaimed from `WinSxS`.  
  - **Irreversible**: `/ResetBase` removes the ability to uninstall certain updates.

---

#### `CleanTempFolders.ps1`

Focused script to clean out user and system TEMP folders.

**What it does:**

- Targets:
  - User temp: `C:\Users\<accountusernamehere>\AppData\Local\Temp`
  - System temp: `C:\Windows\Temp`
- Defines a `Clean-TempFolder` function that:
  - Recursively deletes files (including hidden/system) in the target folder.
  - Recursively deletes subdirectories in the target folder.
  - Logs errors when a file or directory cannot be deleted.
- Prints progress messages:
  - `"Cleaning user TEMP folder..."`
  - `"Cleaning system TEMP folder..."`
  - `"TEMP folders cleanup completed."`

> 🔧 **Customization Note**  
> The script currently uses a hard-coded user path with a placeholder:
>
> `C:\Users\<accountusernamehere>\AppData\Local\Temp`  
>
> Replace `<accountusernamehere>` with the actual username, or refactor to use environment variables like `$env:USERNAME` or `$env:TEMP` if you want it to be more generic.

---

## ▶️ Usage

> 💡 Always review a script before running it, especially on production machines.

### Running `Windows_Deep_Clean.ps1`

**Basic cleanup:**

~~~powershell
# From the repo root
& ".\Windows Cleanup\Windows_Deep_Clean.ps1"
~~~

**With deep component cleanup (DISM):**

~~~powershell
# WARNING: This is more aggressive and can be irreversible.
& ".\Windows Cleanup\Windows_Deep_Clean.ps1" -DeepComponentCleanup
~~~

> ⚠️ Recommended to run in an elevated PowerShell session (Run as Administrator).

---

### Running `CleanTempFolders.ps1`

After updating the username placeholder in the script:

~~~powershell
# From the repo root
& ".\Windows Cleanup\CleanTempFolders.ps1"
~~~

You can also edit the paths inside the script to use environment variables if you want it to work for any user.

---

### Execution Policy

If you encounter execution policy issues when running scripts:

~~~powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
~~~

This only affects the **current PowerShell session**.

---

## 📦 Requirements

- Windows 10, Windows 11, or Windows Server  
- PowerShell 5.1 or PowerShell 7+  
- Local Administrator rights for most cleanup operations  
- Internet access **not required** for these scripts  

---

## ⚠️ Disclaimer

These scripts are provided **as-is** with no warranty.  

Use at your own risk. Always:

- Review the script before running it.  
- Test in a lab / non-production environment first.  
- Be extra careful with:
  - `DISM /StartComponentCleanup /ResetBase`
  - Any script that deletes files recursively

---

## 🤝 Contributing

Contributions are welcome!

You can help by:

- Improving existing scripts  
- Adding new Windows maintenance or automation scripts  
- Submitting issues or suggestions  

Feel free to open a pull request.

---

## 👤 Author

**Nick Garcia**  
GitHub: nickngarcia

---
