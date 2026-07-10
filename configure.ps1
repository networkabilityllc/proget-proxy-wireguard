function Write-BoxedText {
    param (
        [string]$Text,
        [char]$BorderChar = '-',
        [int]$PaddingSize = 10
    )
    
    # Convert the BorderChar to a string
    $BorderString = $BorderChar.ToString()
    
    # Calculate the total length of the boxed text
    $totalLength = $Text.Length + ($PaddingSize * 2)
    
    # Ensure the total length is at least as long as the text
    if ($totalLength -lt $Text.Length) {
        $totalLength = $Text.Length
    }
    
    # Calculate the padding on both sides to center the text
    $padding = ($totalLength - $Text.Length) / 2
    
    # Create the top border
    $border = $BorderString * $totalLength
    
    # Create breaks above and below the boxed text
    Write-Host "`n"
    
    # Create the boxed text with padding and center the text
    $boxedText = (' ' * $padding) + $Text + (' ' * ($totalLength - $padding - $Text.Length))
    
    # Output the top border, boxed text, and bottom border
    Write-Host $border -ForegroundColor White -BackgroundColor Green
    Write-Host $boxedText -ForegroundColor White -BackgroundColor Green
    Write-Host $border -ForegroundColor White -BackgroundColor Green
    
    # Create a break below the boxed text
    Write-Host "`n"
}



function Check-GitInstallation {
    # Path to git.exe
    $gitPath = "C:\Program Files\Git\bin\git.exe"
    
    # Display a boxed message
    Write-BoxedText "Checking for Git installation"
    
    # Check if the repository has been cloned
    Write-BoxedText "Checking if the repository has been cloned"
    
    $repoPath = "c:\prep\NewWindowsScripts"
    if (-not (Test-Path -Path $repoPath)) {
        # Clone the GitHub repository
        $gitRepoUrl = "https://github.com/networkabilityllc/NewWindowsScripts"
        Start-Process -FilePath $gitPath -ArgumentList "clone", $gitRepoUrl, $repoPath
    } else {
        # Update the repository
        Set-Location -Path $repoPath
        & $gitPath pull
    }
}

# Call the function to check Git installation
Check-GitInstallation

$chocoPath = "C:\ProgramData\chocolatey\choco.exe"
# Check if Python is already installed
$pythonInstalled = Test-Path "C:\python310\python.exe"

# Check if Git is already installed
$gitInstalled = (Get-Command git -ErrorAction SilentlyContinue) -ne $null

# Install Python using Chocolatey if not already installed
if (-not $pythonInstalled) {
    & $chocoPath install python310 --force
}

# Install Git using Chocolatey if not already installed
if (-not $gitInstalled) {
    & C:\ProgramData\chocolatey\choco install git --force

    }
Write-BoxedText "Git and Python installed."


# Load the PresentationFramework assembly
# Add-Type -AssemblyName PresentationFramework

# Run Boxstarter shell and enter interactive commands
& 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Run the commands interactively
# Check if UAC is already disabled
$uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue

# Only disable UAC if it's not already disabled
if ($uacStatus -eq $null -or $uacStatus.EnableLUA -ne 0) {
    Disable-UAC -Confirm:$false
    Write-BoxedText "UAC has been disabled."
    
} else {
       Write-BoxedText "UAC is already disabled."
    
}

# Check if Bing Search is already disabled
$bingSearchDisabled = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search").BingSearchEnabled -eq 0

# Output "Disabled" if already disabled, or run the command to disable it
if ($bingSearchDisabled) {
   Write-BoxedText "Bing Search is already disabled."
    } else {
    # Run the command to disable Bing Search
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0 -Force
    Write-BoxedText "Bing Search has been disabled."
    
}



Disable-GameBarTips

Write-BoxedText "Game Bar Tips have been disabled."
Write-BoxedText "Disabling Windows Consumer Experience Features."
# Write-BoxedText "Disabling Open File Explorer to Quick Access."
# Write-BoxedText "Disabling Show Recent Files in Quick Access."
# Write-BoxedText "Disabling Show Frequent Folders in Quick Access." 
Write-BoxedText "Disabling Expand to Open Folder."
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions  
Write-BoxedText "Setting Taskbar size Large."
Set-BoxstarterTaskbarOptions -Size Large 
Write-BoxedText "Setting Taskbar Dock Bottom."
Set-BoxstarterTaskbarOptions -Dock Bottom 
Write-BoxedText "Search Box Disabled."
Set-BoxstarterTaskbarOptions -DisableSearchBox 
Set-BoxstarterTaskbarOptions -AlwaysShowIconsOn 
Write-BoxedText "Show Taskbar Icons set to Always. May not work in latest version of Windows 11"
Set-BoxstarterTaskbarOptions -Combine Always
Write-BoxedText "Setting Taskbar to Combine Always for Running Apps."
#-------------------------------------------------------------
# Remove Taskbar Chat Icon

Write-BoxedText "Removing Taskbar Chat Icon."

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v TaskbarMn /t REG_DWORD /d 0

# Disable Windows Consumer Experience Features

Write-BoxedText "Disabling Windows Consumer Experience Features."
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f
#-------------------------------------------------------------
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /d 0 /t REG_DWORD /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /v SystemPaneSuggestionsEnabled /d 0 /t REG_DWORD /f
# Restore the classic right-click context menu

Write-BoxedText "Restoring the classic right-click context menu."
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

# Set Mouse Hover Time for Taskbar to a very long time to prevent hover text
Write-BoxedText "Setting Mouse Hover Time for Taskbar to a very long time to delay hover text" 
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value 10000

# Set the registry value to show hidden files and folders for the current user
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Set the registry value to show hidden files and folders for all users
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" -Name "CheckedValue" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL" -Name "DefaultValue" -Value 1


# Set the paths
$shortcutPath = "C:\Users\Default\Desktop\Post User Install.lnk"
$targetPath = "C:\prep\NewWindowsScripts\post-user-install.bat"
$iconPath = "C:\prep\NewWindowsScripts\installme.ico"

# Create the WScript Shell Object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath

# Set the shortcut's icon to the provided .ico file
$Shortcut.IconLocation = $iconPath

# Additional optional setting
$Shortcut.Description = "Shortcut to Post-User-Install Script"

# Save the shortcut
$Shortcut.Save()
#Requires -RunAsAdministrator

# ------------------------------------------------------------
# This section adds the "Open Command Prompt Here" option to
# the context menu when you right-click 
# ------------------------------------------------------------
#------------------------------------------------------------
# Because the next section opens a dialog box, which may
# open behind the current window, we need to display a
# message to the user to look for it
#------------------------------------------------------------

# Display a screen prompt to the user 
Write-Host "Please look behind this console window     " -ForegroundColor White -BackgroundColor Blue
Write-Host "for any open dialog boxes or user prompts. " -ForegroundColor White -BackgroundColor Blue
Write-Host "Close them before continuing.              " -ForegroundColor White -BackgroundColor Blue
# ------------------------------------------------------------
# Add the "Open Command Prompt Here" option to the context menu
# ------------------------------------------------------------

# Import registry settings
regedit.exe /s "C:\prep\NewWindowsScripts\addprompts.reg"

# Display a message to the user
$popupMessage = "Right click to open Command Prompt added.`r`nShift-Right Click to open PowerShell and Elevated Command Prompt added.`r`nClick OK to continue."
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.MessageBox]::Show($popupMessage, "Notification", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

# ------------------------------------------------------------
# Turn on numlock at startup
# This uses C# code to send a keypress to turn on numlock
# It's more reliable to do this in C# than in PowerShell
# This may not work on non-US keyboards
# Many thanks to the helpful tutorials at https://www.byteinthesky.com/powershell/
# ------------------------------------------------------------
Write-BoxedText "Turning on Numlock at Startup. See comments in script for details."
# Adding a custom C# class definition by using Add-Type
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NumLockControl {
    const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    const uint KEYEVENTF_KEYUP = 0x0002;
    const int VK_NUMLOCK = 0x90;

    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public static void EnableNumLock() {
        keybd_event((byte)VK_NUMLOCK, 0x45, KEYEVENTF_EXTENDEDKEY, (UIntPtr)0);
        keybd_event((byte)VK_NUMLOCK, 0x45, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, (UIntPtr)0);
    }
}
"@

[NumLockControl]::EnableNumLock()



# Define the list of registry paths to remove Git context menu entries
    $registryPathsToRemove = @(
        "HKCU:\Software\Classes\Directory\shell\git_gui",
        "HKCU:\Software\Classes\Directory\shell\git_shell",
        "HKCU:\Software\Classes\LibraryFolder\background\shell\git_gui",
        "HKCU:\Software\Classes\LibraryFolder\background\shell\git_shell",
        "HKLM:\SOFTWARE\Classes\Directory\background\shell\git_gui",
        "HKLM:\SOFTWARE\Classes\Directory\background\shell\git_shell"
    )

    # Loop through the list of registry paths and remove them
    foreach ($path in $registryPathsToRemove) {
        # Remove the registry key and its children
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }
    
    Write-BoxedText "Git context menu entries removed from the registry."

#-------------------------------------------------------------
# Install XAML 2.7 in case Windows 10 is pre-22H2
#-------------------------------------------------------------
Write-BoxedText "Installing XAML 2.7 and VCLIBS 14"    
choco install microsoft-ui-xaml -y --force
choco install microsoft-vclibs-140-00 -y --force
#-------------------------------------------------------------
# Start App Cleanup Script to remove Junk Windows Apps
#-------------------------------------------------------------
# Write-BoxedText "Starting App Cleanup Script and removing Junk Windows Apps"
# $scriptPath = "C:\prep\NewWindowsScripts\cleanupapps.ps1"
# Invoke-Expression -Command "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`""

#-------------------------------------------------------------
# Install VCLibs and XAML frameworks required by modern MSIX apps
# TranslucentTB, Terminal, and other packages depend on these.
#-------------------------------------------------------------
Write-BoxedText "Installing Microsoft Visual C++ Runtime and XAML Frameworks"

# Ensure TLS 1.2 is used for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#-------------------------------------------------------------
# Install Microsoft.VCLibs.x64.14.00.Desktop
#-------------------------------------------------------------
Write-Host "Downloading and installing Microsoft.VCLibs.x64.14.00.Desktop..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"

try {
    Add-AppxPackage "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction Stop
}
catch {
    $hresult = $_.Exception.HResult
    switch ($hresult) {
        -2147009290 {  # 0x80073D06 – newer version already installed
            Write-Host "A newer version of Microsoft.VCLibs.x64.14.00.Desktop is already installed. Skipping..." -ForegroundColor Yellow
        }
        default {
            Write-Host "Non-critical Add-AppxPackage error ($([System.String]::Format('0x{0:X8}', $hresult))) encountered. Continuing..." -ForegroundColor DarkYellow
        }
    }
}


#-------------------------------------------------------------
# Install Microsoft.UI.Xaml.2.8 (x64)
#-------------------------------------------------------------
Write-Host "Downloading and installing Microsoft.UI.Xaml.2.8.x64..." -ForegroundColor Cyan
$pkgPath = "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx"

Invoke-WebRequest `
    -Uri "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx" `
    -OutFile $pkgPath

try {
    Add-AppxPackage -Path $pkgPath -ErrorAction Stop
}
catch {
    $hresult = $_.Exception.HResult

    switch ($hresult) {
        -2147009290 {  # 0x80073D06 – newer version already installed
            Write-Host "A newer version of Microsoft.UI.Xaml is already installed. Skipping..." -ForegroundColor Yellow
        }
        default {
            $hex = [System.String]::Format("0x{0:X8}", $hresult)
            Write-Host "Newer version already installed ($hex). Continuing..." -ForegroundColor DarkYellow
        }
    }
}

Write-BoxedText "Framework installation complete."



#-------------------------------------------------------------
# Check for and Disable Hibernation
#-------------------------------------------------------------

$result = Invoke-Expression -Command "powercfg.exe /hibernate off"
if ($result -eq 0) {
    Write-BoxedText "Hibernation has been disabled successfully."
} else {
    Write-BoxedText "Hibernation already disabled."
}

# Check for and disable Sleep Menu Item from Shutdown Button

# Define the Registry path for the Start Menu customization
$registryPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"

# Check if the registry path exists, and create it if it doesn't
if (-Not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

# Set the "ShowSleepOption" value to 0 to remove the Sleep option
$showSleepOptionValue = Get-ItemProperty -Path $registryPath -Name "ShowSleepOption" -ErrorAction SilentlyContinue

# Check if the "ShowSleepOption" value exists, and create it if it doesn't
if ($showSleepOptionValue -eq $null) {
    New-ItemProperty -Path $registryPath -Name "ShowSleepOption" -Value 0 -PropertyType DWORD
} else {
    # If the value exists, set it to 0
    Set-ItemProperty -Path $registryPath -Name "ShowSleepOption" -Value 0
}

# Force a refresh of the taskbar and Start menu
Stop-Process -Name explorer -Force
Start-Process explorer



Write-BoxedText "The Sleep option has been removed from the Start menu."


#-------------------------------------------------------------
# Start Chocolatey App Installer
#-------------------------------------------------------------

Write-BoxedText "Starting Chocolatey App Installer."

C:\Python310\python.exe c:\prep\NewWindowsScripts\install_apps.py


#-------------------------------------------------------------
# Add Boxstart Icon to the Default and the current User's Desktops
#-------------------------------------------------------------

Write-BoxedText "Adding Boxstarter Shell shortcut to the Default and current user's Desktops."

# Define the location for the shortcut for the Default User
$defaultUserShortcutPath = "C:\Users\Default\Desktop\Box Starter.lnk"

# Define the location for the shortcut for the current user
$currentuserShortcutPath = "$($env:USERPROFILE)\Desktop\Box Starter.lnk"

# Define the target PowerShell command
$command = 'C:\ProgramData\Boxstarter\BoxstarterShell.ps1'

# Define the icon location
$iconLocation = "C:\ProgramData\Boxstarter\boxlogo.ico"

# Define the "Start In" (working directory) path
$startInPath = 'C:\ProgramData\Boxstarter\'

# Create the WScript Shell Object
$WshShell = New-Object -comObject WScript.Shell

# Create the shortcut for the Default User
$ShortcutDefaultUser = $WshShell.CreateShortcut($defaultUserShortcutPath)
$ShortcutDefaultUser.TargetPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ShortcutDefaultUser.Arguments = "-ExecutionPolicy bypass -NoExit -File `"$command`""
$ShortcutDefaultUser.IconLocation = $iconLocation
$ShortcutDefaultUser.WorkingDirectory = $startInPath
$ShortcutDefaultUser.Save()

# Create the shortcut for the current user
$ShortcutCurrentUser = $WshShell.CreateShortcut($currentuserShortcutPath)
$ShortcutCurrentUser.TargetPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ShortcutCurrentUser.Arguments = "-ExecutionPolicy bypass -NoExit -File `"$command`""
$ShortcutCurrentUser.IconLocation = $iconLocation
$ShortcutCurrentUser.WorkingDirectory = $startInPath
$ShortcutCurrentUser.Save()

#-------------------------------------------------------------
# Remove the Boxstarter shortcut from the Public Folder
# that was created during the Boxstarter installation
#-------------------------------------------------------------

# Write-BoxedText "Removing Boxstarter Shell shortcut from Public Desktop."


# if (Test-Path "C:\Users\Public\Desktop\Boxstarter Shell.lnk") { Remove-Item -Path "C:\Users\Public\Desktop\Boxstarter Shell.lnk" }

# Write-BoxedText "Boxstarter Shell shortcut removed from Public Desktop."


#-------------------------------------------------------------
# Toggle UAC Section
# ------------------------------------------------------------ 

Write-BoxedText "Toggling UAC."

# Load the System.Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Function to toggle UAC
# Display a dialog box to ask if the user wants to re-enable UAC
$dialogResult = [System.Windows.Forms.MessageBox]::Show("Do you want to re-enable UAC?", "UAC Re-enable", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
    Enable-UAC
    
    Write-BoxedText "UAC has been re-enabled."
    
} else {
    
    Write-BoxedText "UAC remains disabled."
    
}