#Requires -RunAsAdministrator

# ------------------------------------------------------------
# Paths and configuration
# ------------------------------------------------------------

$prepPath = 'C:\prep'
$repoPath = 'C:\prep\NewWindowsScripts'
$gitRepoUrl = 'https://github.com/networkabilityllc/NewWindowsScripts'
$chocoPath = 'C:\ProgramData\chocolatey\choco.exe'
$pythonPath = 'C:\Python310\python.exe'
$defaultGitPath = 'C:\Program Files\Git\bin\git.exe'

# ------------------------------------------------------------
# Display a boxed status message
# ------------------------------------------------------------

function Write-BoxedText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Text,

        [char]$BorderChar = '-',

        [ValidateRange(0, [int]::MaxValue)]
        [int]$PaddingSize = 10
    )

    $totalLength = $Text.Length + ($PaddingSize * 2)
    $spaces = ' ' * $PaddingSize
    $boxedText = "$spaces$Text$spaces"
    $border = [string]$BorderChar * $totalLength

    Write-Host ''
    Write-Host $border -ForegroundColor White -BackgroundColor Green
    Write-Host $boxedText -ForegroundColor White -BackgroundColor Green
    Write-Host $border -ForegroundColor White -BackgroundColor Green
    Write-Host ''
}

# ------------------------------------------------------------
# Create a registry key and set a registry value
# ------------------------------------------------------------

function Set-RegistryValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [Microsoft.Win32.RegistryValueKind]$Type
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty `
        -Path $Path `
        -Name $Name `
        -Value $Value `
        -PropertyType $Type `
        -Force | Out-Null
}

# ------------------------------------------------------------
# Set the unnamed default value of a registry key
# ------------------------------------------------------------

function Set-RegistryDefaultValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    Set-Item -LiteralPath $Path -Value $Value
}

# ------------------------------------------------------------
# Create the working directory
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $prepPath)) {
    New-Item -Path $prepPath -ItemType Directory -Force | Out-Null
}

Set-Location -LiteralPath $prepPath

# ------------------------------------------------------------
# Verify Chocolatey
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $chocoPath)) {
    Write-BoxedText 'Chocolatey is not installed. Cannot continue.'
    Read-Host 'Press Enter to exit'
    exit 1
}

# ------------------------------------------------------------
# Install Python if necessary
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $pythonPath)) {
    Write-BoxedText 'Installing Python 3.10'

    & $chocoPath install python310 --force

    if ($LASTEXITCODE -ne 0) {
        Write-BoxedText 'Python installation failed.'
        Read-Host 'Press Enter to exit'
        exit 1
    }
}
else {
    Write-BoxedText 'Python 3.10 is already installed'
}

# ------------------------------------------------------------
# Install Git if necessary
# ------------------------------------------------------------

$gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue

if (-not $gitCommand -and -not (Test-Path -LiteralPath $defaultGitPath)) {
    Write-BoxedText 'Installing Git'

    & $chocoPath install git --force

    if ($LASTEXITCODE -ne 0) {
        Write-BoxedText 'Git installation failed.'
        Read-Host 'Press Enter to exit'
        exit 1
    }

    Start-Sleep -Seconds 3
}

$gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue

if ($gitCommand) {
    $gitPath = $gitCommand.Source
}
elseif (Test-Path -LiteralPath $defaultGitPath) {
    $gitPath = $defaultGitPath
}
else {
    Write-BoxedText 'Git was installed, but git.exe could not be found.'
    Read-Host 'Press Enter to exit'
    exit 1
}

Write-BoxedText 'Git and Python are installed'

# ------------------------------------------------------------
# Clone or update the repository
# ------------------------------------------------------------

Write-BoxedText 'Checking whether the repository has been cloned'

if (-not (Test-Path -LiteralPath $repoPath)) {
    Write-BoxedText 'Cloning the repository'

    & $gitPath clone $gitRepoUrl $repoPath

    if ($LASTEXITCODE -ne 0) {
        Write-BoxedText 'Repository clone failed.'
        Read-Host 'Press Enter to exit'
        exit 1
    }
}
else {
    Write-BoxedText 'Updating the repository'

    & $gitPath -C $repoPath pull --ff-only

    if ($LASTEXITCODE -ne 0) {
        Write-BoxedText 'Repository update failed.'
        Read-Host 'Press Enter to exit'
        exit 1
    }
}

# ------------------------------------------------------------
# Disable UAC
#
# This replaces the Boxstarter Disable-UAC command.
# A restart is required for an EnableLUA change to fully apply.
# ------------------------------------------------------------

$uacRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$uacStatus = Get-ItemProperty `
    -LiteralPath $uacRegistryPath `
    -Name 'EnableLUA' `
    -ErrorAction SilentlyContinue

if ($null -eq $uacStatus -or $uacStatus.EnableLUA -ne 0) {
    Set-RegistryValue `
        -Path $uacRegistryPath `
        -Name 'EnableLUA' `
        -Value 0 `
        -Type DWord

    Write-BoxedText 'UAC has been disabled. A restart is required.'
}
else {
    Write-BoxedText 'UAC is already disabled'
}

# ------------------------------------------------------------
# Disable Bing web search for the current user
# ------------------------------------------------------------

Write-BoxedText 'Disabling Bing Search'

$searchRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'

Set-RegistryValue `
    -Path $searchRegistryPath `
    -Name 'BingSearchEnabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $searchRegistryPath `
    -Name 'CortanaConsent' `
    -Value 0 `
    -Type DWord

# Apply the corresponding policy where supported
$searchPolicyPath = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'

Set-RegistryValue `
    -Path $searchPolicyPath `
    -Name 'DisableSearchBoxSuggestions' `
    -Value 1 `
    -Type DWord

Write-BoxedText 'Bing Search has been disabled'

# ------------------------------------------------------------
# Disable Game Bar tips and related Game DVR features
#
# This replaces the Boxstarter Disable-GameBarTips command.
# ------------------------------------------------------------

Write-BoxedText 'Disabling Game Bar Tips'

$gameBarRegistryPath = 'HKCU:\Software\Microsoft\GameBar'

Set-RegistryValue `
    -Path $gameBarRegistryPath `
    -Name 'ShowStartupPanel' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $gameBarRegistryPath `
    -Name 'UseNexusForGameBarEnabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $gameBarRegistryPath `
    -Name 'GamePanelStartupTipIndex' `
    -Value 3 `
    -Type DWord

$gameConfigStorePath = 'HKCU:\System\GameConfigStore'

Set-RegistryValue `
    -Path $gameConfigStorePath `
    -Name 'GameDVR_Enabled' `
    -Value 0 `
    -Type DWord

$gameDvrPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'

Set-RegistryValue `
    -Path $gameDvrPolicyPath `
    -Name 'AllowGameDVR' `
    -Value 0 `
    -Type DWord

Write-BoxedText 'Game Bar Tips have been disabled'

# ------------------------------------------------------------
# Configure Explorer options
#
# This replaces:
#
# Set-WindowsExplorerOptions
#     -EnableShowHiddenFilesFoldersDrives
#     -EnableShowFileExtensions
# ------------------------------------------------------------

Write-BoxedText 'Configuring Windows Explorer options'

$explorerAdvancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

# Show hidden files and folders
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'Hidden' `
    -Value 1 `
    -Type DWord

# Show protected operating-system files
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'ShowSuperHidden' `
    -Value 1 `
    -Type DWord

# Show file extensions
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'HideFileExt' `
    -Value 0 `
    -Type DWord

# Expand Explorer to the currently open folder
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'NavPaneExpandToCurrentFolder' `
    -Value 1 `
    -Type DWord

Write-BoxedText 'Explorer settings have been configured'

# ------------------------------------------------------------
# Configure taskbar options
#
# These replace the Set-BoxstarterTaskbarOptions commands.
# ------------------------------------------------------------

Write-BoxedText 'Configuring Taskbar options'

# Remove the Chat icon
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'TaskbarMn' `
    -Value 0 `
    -Type DWord

# Remove Widgets
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'TaskbarDa' `
    -Value 0 `
    -Type DWord

# Align the Start button to the left
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'TaskbarAl' `
    -Value 0 `
    -Type DWord

# Use the large taskbar size where the Windows build supports it
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'TaskbarSi' `
    -Value 2 `
    -Type DWord

# Always combine taskbar buttons
Set-RegistryValue `
    -Path $explorerAdvancedPath `
    -Name 'TaskbarGlomLevel' `
    -Value 0 `
    -Type DWord

# Disable the taskbar search box
Set-RegistryValue `
    -Path $searchRegistryPath `
    -Name 'SearchboxTaskbarMode' `
    -Value 0 `
    -Type DWord

# Always show notification-area icons
$explorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'

Set-RegistryValue `
    -Path $explorerRegistryPath `
    -Name 'EnableAutoTray' `
    -Value 0 `
    -Type DWord

Write-BoxedText 'Taskbar options have been configured'

# ------------------------------------------------------------
# Disable Windows Consumer Experience features
# ------------------------------------------------------------

Write-BoxedText 'Disabling Windows Consumer Experience features'

$cloudContentPolicyPath = 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent'

Set-RegistryValue `
    -Path $cloudContentPolicyPath `
    -Name 'DisableWindowsConsumerFeatures' `
    -Value 1 `
    -Type DWord

$contentDeliveryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'ContentDeliveryAllowed' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'SilentInstalledAppsEnabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'SystemPaneSuggestionsEnabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'SubscribedContent-338388Enabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'SubscribedContent-338389Enabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'SubscribedContent-353694Enabled' `
    -Value 0 `
    -Type DWord

Set-RegistryValue `
    -Path $contentDeliveryPath `
    -Name 'SubscribedContent-353696Enabled' `
    -Value 0 `
    -Type DWord

Write-BoxedText 'Windows Consumer Experience features have been disabled'

# ------------------------------------------------------------
# Restore the classic Windows 11 right-click context menu
# ------------------------------------------------------------

Write-BoxedText 'Restoring the classic right-click context menu'

$classicContextMenuPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'

Set-RegistryDefaultValue `
    -Path $classicContextMenuPath `
    -Value ''

# ------------------------------------------------------------
# Increase mouse hover time
# ------------------------------------------------------------

Write-BoxedText 'Increasing the taskbar mouse hover delay'

$mouseRegistryPath = 'HKCU:\Control Panel\Mouse'

Set-RegistryValue `
    -Path $mouseRegistryPath `
    -Name 'MouseHoverTime' `
    -Value '10000' `
    -Type String

# ------------------------------------------------------------
# Create the Default User Post User Install shortcut
# ------------------------------------------------------------

Write-BoxedText 'Creating the Post User Install shortcut'

$defaultDesktopPath = 'C:\Users\Default\Desktop'
$shortcutPath = Join-Path `
    -Path $defaultDesktopPath `
    -ChildPath 'Post User Install.lnk'

$targetPath = Join-Path `
    -Path $repoPath `
    -ChildPath 'post-user-install.bat'

$iconPath = Join-Path `
    -Path $repoPath `
    -ChildPath 'installme.ico'

if (-not (Test-Path -LiteralPath $defaultDesktopPath)) {
    New-Item `
        -Path $defaultDesktopPath `
        -ItemType Directory `
        -Force | Out-Null
}

$wshShell = New-Object -ComObject WScript.Shell

try {
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.WorkingDirectory = $repoPath
    $shortcut.IconLocation = $iconPath
    $shortcut.Description = 'Shortcut to Post-User-Install Script'
    $shortcut.Save()
}
finally {
    if ($null -ne $shortcut) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut)
    }

    if ($null -ne $wshShell) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($wshShell)
    }

    Remove-Variable shortcut -ErrorAction SilentlyContinue
    Remove-Variable wshShell -ErrorAction SilentlyContinue

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

# ------------------------------------------------------------
# Add Command Prompt and PowerShell context-menu entries
# ------------------------------------------------------------

Write-Host 'Please look behind this console window     ' -ForegroundColor White -BackgroundColor Blue
Write-Host 'for any open dialog boxes or user prompts. ' -ForegroundColor White -BackgroundColor Blue
Write-Host 'Close them before continuing.              ' -ForegroundColor White -BackgroundColor Blue

$contextMenuRegistryFile = Join-Path `
    -Path $repoPath `
    -ChildPath 'addprompts.reg'

if (Test-Path -LiteralPath $contextMenuRegistryFile) {
    & regedit.exe /s $contextMenuRegistryFile

    if ($LASTEXITCODE -eq 0) {
        Add-Type -AssemblyName System.Windows.Forms

        $popupMessage = @"
Right-click to open Command Prompt has been added.
Shift-right-click to open PowerShell and Elevated Command Prompt has been added.

Click OK to continue.
"@

        [void][System.Windows.Forms.MessageBox]::Show(
            $popupMessage,
            'Notification',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    else {
        Write-BoxedText 'The context-menu registry import failed.'
    }
}
else {
    Write-BoxedText 'The addprompts.reg file was not found.'
}

# ------------------------------------------------------------
# Turn on Num Lock
# ------------------------------------------------------------

Write-BoxedText 'Turning on Num Lock'

if (-not ('NumLockControl' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class NumLockControl
{
    private const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    private const uint KEYEVENTF_KEYUP = 0x0002;
    private const byte VK_NUMLOCK = 0x90;

    [DllImport("user32.dll")]
    private static extern void keybd_event(
        byte bVk,
        byte bScan,
        uint dwFlags,
        UIntPtr dwExtraInfo
    );

    [DllImport("user32.dll")]
    private static extern short GetKeyState(int nVirtKey);

    public static void EnableNumLock()
    {
        bool isEnabled = (GetKeyState(VK_NUMLOCK) & 1) != 0;

        if (!isEnabled)
        {
            keybd_event(
                VK_NUMLOCK,
                0x45,
                KEYEVENTF_EXTENDEDKEY,
                UIntPtr.Zero
            );

            keybd_event(
                VK_NUMLOCK,
                0x45,
                KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,
                UIntPtr.Zero
            );
        }
    }
}
"@
}

[NumLockControl]::EnableNumLock()

# Set the initial Num Lock state for the current user
Set-RegistryValue `
    -Path 'HKCU:\Control Panel\Keyboard' `
    -Name 'InitialKeyboardIndicators' `
    -Value '2' `
    -Type String

# ------------------------------------------------------------
# Remove Git context-menu entries
# ------------------------------------------------------------

$registryPathsToRemove = @(
    'HKCU:\Software\Classes\Directory\shell\git_gui'
    'HKCU:\Software\Classes\Directory\shell\git_shell'
    'HKCU:\Software\Classes\LibraryFolder\background\shell\git_gui'
    'HKCU:\Software\Classes\LibraryFolder\background\shell\git_shell'
    'HKLM:\SOFTWARE\Classes\Directory\background\shell\git_gui'
    'HKLM:\SOFTWARE\Classes\Directory\background\shell\git_shell'
)

foreach ($path in $registryPathsToRemove) {
    Remove-Item `
        -LiteralPath $path `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue
}

Write-BoxedText 'Git context-menu entries have been removed'

# ------------------------------------------------------------
# Install VCLibs and XAML frameworks required by modern MSIX apps
# ------------------------------------------------------------

Write-BoxedText 'Installing Microsoft Visual C++ and XAML frameworks'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ------------------------------------------------------------
# Install Microsoft.VCLibs.x64.14.00.Desktop
# ------------------------------------------------------------

$vclibsPackagePath = Join-Path `
    -Path $env:TEMP `
    -ChildPath 'Microsoft.VCLibs.x64.14.00.Desktop.appx'

Write-Host 'Downloading Microsoft.VCLibs.x64.14.00.Desktop...' -ForegroundColor Cyan

try {
    Invoke-WebRequest `
        -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' `
        -OutFile $vclibsPackagePath `
        -UseBasicParsing `
        -ErrorAction Stop

    Add-AppxPackage `
        -Path $vclibsPackagePath `
        -ErrorAction Stop

    Write-Host 'Microsoft.VCLibs was installed successfully.' -ForegroundColor Green
}
catch {
    $hresult = $_.Exception.HResult
    $hexResult = [System.String]::Format('0x{0:X8}', $hresult)

    if ($hresult -eq -2147009290) {
        Write-Host 'A newer version of Microsoft.VCLibs is already installed.' -ForegroundColor Yellow
    }
    else {
        Write-Host "Microsoft.VCLibs installation returned $hexResult. Continuing." -ForegroundColor DarkYellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    }
}
finally {
    Remove-Item `
        -LiteralPath $vclibsPackagePath `
        -Force `
        -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# Install Microsoft.UI.Xaml 2.8
# ------------------------------------------------------------

$xamlPackagePath = Join-Path `
    -Path $env:TEMP `
    -ChildPath 'Microsoft.UI.Xaml.2.8.x64.appx'

Write-Host 'Downloading Microsoft.UI.Xaml 2.8...' -ForegroundColor Cyan

try {
    Invoke-WebRequest `
        -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' `
        -OutFile $xamlPackagePath `
        -UseBasicParsing `
        -ErrorAction Stop

    Add-AppxPackage `
        -Path $xamlPackagePath `
        -ErrorAction Stop

    Write-Host 'Microsoft.UI.Xaml was installed successfully.' -ForegroundColor Green
}
catch {
    $hresult = $_.Exception.HResult
    $hexResult = [System.String]::Format('0x{0:X8}', $hresult)

    if ($hresult -eq -2147009290) {
        Write-Host 'A newer version of Microsoft.UI.Xaml is already installed.' -ForegroundColor Yellow
    }
    else {
        Write-Host "Microsoft.UI.Xaml installation returned $hexResult. Continuing." -ForegroundColor DarkYellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    }
}
finally {
    Remove-Item `
        -LiteralPath $xamlPackagePath `
        -Force `
        -ErrorAction SilentlyContinue
}

Write-BoxedText 'Framework installation is complete'

# ------------------------------------------------------------
# Disable hibernation
# ------------------------------------------------------------

Write-BoxedText 'Disabling hibernation'

& powercfg.exe /hibernate off

if ($LASTEXITCODE -eq 0) {
    Write-BoxedText 'Hibernation has been disabled'
}
else {
    Write-BoxedText "powercfg.exe returned exit code $LASTEXITCODE"
}

# ------------------------------------------------------------
# Remove the Sleep option from the Start menu
# ------------------------------------------------------------

$sleepPolicyPath = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'

Set-RegistryValue `
    -Path $sleepPolicyPath `
    -Name 'ShowSleepOption' `
    -Value 0 `
    -Type DWord

Write-BoxedText 'The Sleep option has been removed from the Start menu'

# ------------------------------------------------------------
# Restart Explorer to apply current-user shell settings
# ------------------------------------------------------------

Write-BoxedText 'Restarting Windows Explorer'

Stop-Process `
    -Name explorer `
    -Force `
    -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2
Start-Process explorer.exe

# ------------------------------------------------------------
# Start the Chocolatey application installer
# ------------------------------------------------------------

Write-BoxedText 'Starting the Chocolatey App Installer'

$applicationInstallerPath = Join-Path `
    -Path $repoPath `
    -ChildPath 'install_apps.py'

if (-not (Test-Path -LiteralPath $pythonPath)) {
    Write-BoxedText "Python was not found at $pythonPath"
}
elseif (-not (Test-Path -LiteralPath $applicationInstallerPath)) {
    Write-BoxedText "The application installer was not found at $applicationInstallerPath"
}
else {
    & $pythonPath $applicationInstallerPath

    if ($LASTEXITCODE -ne 0) {
        Write-BoxedText "The application installer returned exit code $LASTEXITCODE"
    }
}

# ------------------------------------------------------------
# Ask whether UAC should be re-enabled
#
# This replaces the Boxstarter Enable-UAC command.
# ------------------------------------------------------------

Write-BoxedText 'UAC Configuration'

Add-Type -AssemblyName System.Windows.Forms

$dialogResult = [System.Windows.Forms.MessageBox]::Show(
    'Do you want to re-enable UAC?',
    'UAC Re-enable',
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
    Set-RegistryValue `
        -Path $uacRegistryPath `
        -Name 'EnableLUA' `
        -Value 1 `
        -Type DWord

    Write-BoxedText 'UAC has been re-enabled. A restart is required.'
}
else {
    Write-BoxedText 'UAC remains disabled'
}

Write-BoxedText 'Current-user configuration is complete'

Read-Host 'Press Enter to close'