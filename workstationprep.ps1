#Requires -RunAsAdministrator

# ------------------------------------------------------------
# Create workstation prep working directory and navigate to it
# ------------------------------------------------------------

$prepDir = 'C:\prep'

if (-not (Test-Path -LiteralPath $prepDir)) {
    New-Item -Path $prepDir -ItemType Directory -Force | Out-Null
}

Set-Location -LiteralPath $prepDir

# ------------------------------------------------------------
# Temporarily allow script execution for this PowerShell process
# ------------------------------------------------------------

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# ------------------------------------------------------------
# Load Windows Forms
# ------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# Function to prompt the user with Yes, No, and Help buttons
# ------------------------------------------------------------

function Get-Choice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [string]$DialogTitle,

        [Parameter(Mandatory)]
        [string]$HelpText
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $DialogTitle
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ControlBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Prompt
    $label.Size = New-Object System.Drawing.Size(350, 60)
    $label.Location = New-Object System.Drawing.Point(25, 20)
    $form.Controls.Add($label)

    $buttonYes = New-Object System.Windows.Forms.Button
    $buttonYes.Text = 'Yes'
    $buttonYes.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $buttonYes.Location = New-Object System.Drawing.Point(50, 120)
    $form.Controls.Add($buttonYes)

    $buttonNo = New-Object System.Windows.Forms.Button
    $buttonNo.Text = 'No'
    $buttonNo.DialogResult = [System.Windows.Forms.DialogResult]::No
    $buttonNo.Location = New-Object System.Drawing.Point(150, 120)
    $form.Controls.Add($buttonNo)

    $helpButton = New-Object System.Windows.Forms.Button
    $helpButton.Text = 'Help'
    $helpButton.Location = New-Object System.Drawing.Point(250, 120)
    $form.Controls.Add($helpButton)

    $form.AcceptButton = $buttonYes
    $form.CancelButton = $buttonNo

    $form.Add_Shown({
        $form.Activate()
    })

    $helpButton.Add_Click({
        $helpForm = New-Object System.Windows.Forms.Form
        $helpForm.Text = 'Help'
        $helpForm.Size = New-Object System.Drawing.Size(400, 275)
        $helpForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
        $helpForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $helpForm.MaximizeBox = $false
        $helpForm.MinimizeBox = $false
        $helpForm.TopMost = $true

        $helpLabel = New-Object System.Windows.Forms.Label
        $helpLabel.Text = $HelpText
        $helpLabel.Size = New-Object System.Drawing.Size(350, 160)
        $helpLabel.Location = New-Object System.Drawing.Point(25, 20)
        $helpLabel.AutoSize = $false
        $helpLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
        $helpForm.Controls.Add($helpLabel)

        $helpCloseButton = New-Object System.Windows.Forms.Button
        $helpCloseButton.Text = 'Close'
        $helpCloseButton.Location = New-Object System.Drawing.Point(150, 200)
        $helpCloseButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $helpForm.Controls.Add($helpCloseButton)

        $helpForm.AcceptButton = $helpCloseButton
        $helpForm.CancelButton = $helpCloseButton

        try {
            [void]$helpForm.ShowDialog($form)
        }
        finally {
            $helpForm.Dispose()
        }
    })

    try {
        $result = $form.ShowDialog()
    }
    finally {
        $form.Dispose()
    }

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        return 'Yes'
    }

    return 'No'
}

# ------------------------------------------------------------
# Function to prompt for the Splashtop SOS download
# ------------------------------------------------------------

function Prompt-DownloadSplashtopSOS {
    $helpText = @"
Clicking Yes will download the latest version of
Splashtop SOS to the Default User desktop.

This makes the executable available on the desktop
for newly created user profiles.

It does not install Splashtop SOS for the current user.
"@

    $choice = Get-Choice `
        -Prompt 'Do you want to download Splashtop SOS for new users?' `
        -DialogTitle 'Download Splashtop SOS' `
        -HelpText $helpText

    if ($choice -eq 'Yes') {
        Download-SplashtopSOS
    }
    else {
        Write-Host '----------------------------------------------------' -ForegroundColor White -BackgroundColor Green
        Write-Host '          Skipping Splashtop SOS Download           ' -ForegroundColor White -BackgroundColor Green
        Write-Host '----------------------------------------------------' -ForegroundColor White -BackgroundColor Green
    }
}

# ------------------------------------------------------------
# Function to download Splashtop SOS for new users
# ------------------------------------------------------------

function Download-SplashtopSOS {
    $sosUri = 'https://download.splashtop.com/sos/SplashtopSOS.exe'
    $defaultDesktopPath = 'C:\Users\Default\Desktop'
    $sosPath = Join-Path -Path $defaultDesktopPath -ChildPath 'SplashtopSOS.exe'

    if (-not (Test-Path -LiteralPath $defaultDesktopPath)) {
        New-Item -Path $defaultDesktopPath -ItemType Directory -Force | Out-Null
    }

    try {
        Invoke-WebRequest `
            -Uri $sosUri `
            -OutFile $sosPath `
            -UseBasicParsing `
            -ErrorAction Stop

        Write-Host '----------------------------------------------------' -ForegroundColor White -BackgroundColor Green
        Write-Host ' Splashtop SOS Downloaded for Newly Created Users   ' -ForegroundColor White -BackgroundColor Green
        Write-Host '----------------------------------------------------' -ForegroundColor White -BackgroundColor Green
    }
    catch {
        Write-Host 'Splashtop SOS could not be downloaded.' -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}


# ------------------------------------------------------------
# Prompt for optional Splashtop SOS download
# ------------------------------------------------------------

Prompt-DownloadSplashtopSOS

# ------------------------------------------------------------
# Check for Chocolatey
# ------------------------------------------------------------

Write-Host '------------------------------------------' -ForegroundColor Black -BackgroundColor White
Write-Host '          Checking for Chocolatey         ' -ForegroundColor Black -BackgroundColor White
Write-Host '------------------------------------------' -ForegroundColor Black -BackgroundColor White

# ------------------------------------------------------------
# Chocolatey, ProGet, WireGuard, Git, and repository settings
# ------------------------------------------------------------

$chocoPath = 'C:\ProgramData\chocolatey\choco.exe'
$internalChocoSourceName = 'internal'
$internalChocoSourceUrl = 'http://10.121.116.1:8624/nuget/choco'

$wireGuardConfigPath = 'C:\prep\wg\tech.conf'
$wireGuardExePath = 'C:\Program Files\WireGuard\wireguard.exe'

$proGetHost = '10.121.116.1'
$proGetPort = 8624

$gitDefaultPath = 'C:\Program Files\Git\bin\git.exe'
$gitRepoUrl = 'https://github.com/networkabilityllc/NewWindowsScripts'
$gitBranch = 'proget-proxy-wireguard'
$repoPath = 'C:\prep\NewWindowsScripts'

$chocoWaitTimeoutSeconds = 60
$chocoWaitIntervalSeconds = 5
$chocoWaitElapsedSeconds = 0

# ------------------------------------------------------------
# Install Chocolatey if it is not already installed
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $chocoPath)) {
    Write-Host 'Chocolatey not found. Installing Chocolatey using winget...' -ForegroundColor Cyan

    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
    $wingetInstallExitCode = $null

    if ($wingetCommand) {
        & $wingetCommand.Source source reset --force
        & $wingetCommand.Source install `
            --id Chocolatey.Chocolatey `
            --exact `
            --silent `
            --accept-package-agreements `
            --accept-source-agreements `
            --source winget

        $wingetInstallExitCode = $LASTEXITCODE
    }
    else {
        Write-Host "'winget' is not available on this system." -ForegroundColor Yellow
    }

    while (
        (-not (Test-Path -LiteralPath $chocoPath)) -and
        ($chocoWaitElapsedSeconds -lt $chocoWaitTimeoutSeconds)
    ) {
        Start-Sleep -Seconds $chocoWaitIntervalSeconds
        $chocoWaitElapsedSeconds += $chocoWaitIntervalSeconds
    }

    if (-not (Test-Path -LiteralPath $chocoPath)) {
        Write-Host 'ERROR: Chocolatey installation failed. Cannot continue.' -ForegroundColor Red

        if ($null -ne $wingetInstallExitCode) {
            Write-Host "winget exited with code $wingetInstallExitCode." -ForegroundColor Yellow
        }

        Write-Host ''
        Write-Host 'ACTION REQUIRED:' -ForegroundColor Yellow
        Write-Host 'If this is Windows 10 without winget:' -ForegroundColor Yellow
        Write-Host '1. Run install-winget.bat from the tech USB.' -ForegroundColor Yellow
        Write-Host '2. Rerun this script.' -ForegroundColor Yellow

        exit 1
    }

    Write-Host 'Chocolatey was installed successfully.' -ForegroundColor Green
}
else {
    Write-Host 'Chocolatey is already installed.' -ForegroundColor Green
}

# ------------------------------------------------------------
# Enable Chocolatey global confirmation
# ------------------------------------------------------------

& $chocoPath feature enable --name allowGlobalConfirmation

if ($LASTEXITCODE -ne 0) {
    Write-Host 'Chocolatey global confirmation could not be enabled.' -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Configure Chocolatey to use the internal ProGet source when
# WireGuard and ProGet are available
# ------------------------------------------------------------

$wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
$useInternalChocoSource = $false

if ($wingetCommand) {
    Write-Host 'Winget detected. Installing or updating WireGuard...' -ForegroundColor Cyan

    & $wingetCommand.Source install `
        --id WireGuard.WireGuard `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --source winget

    $wireGuardInstallExitCode = $LASTEXITCODE

    if ($wireGuardInstallExitCode -ne 0) {
        Write-Host "WireGuard installation returned exit code $wireGuardInstallExitCode." -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 5

    if (-not (Test-Path -LiteralPath $wireGuardConfigPath)) {
        Write-Host "WireGuard config not found at $wireGuardConfigPath." -ForegroundColor Yellow
    }
    elseif (-not (Test-Path -LiteralPath $wireGuardExePath)) {
        Write-Host 'WireGuard executable was not found after installation.' -ForegroundColor Yellow
    }
    else {
        Write-Host "WireGuard config found at $wireGuardConfigPath." -ForegroundColor Cyan
        Write-Host 'Importing and starting the WireGuard tunnel...' -ForegroundColor Cyan

        & $wireGuardExePath /installtunnelservice $wireGuardConfigPath
        $wireGuardTunnelExitCode = $LASTEXITCODE

        if ($wireGuardTunnelExitCode -ne 0) {
            Write-Host "WireGuard tunnel installation returned exit code $wireGuardTunnelExitCode." -ForegroundColor Yellow
        }

        Start-Sleep -Seconds 8

        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectAsyncResult = $null

        try {
            $connectAsyncResult = $tcpClient.BeginConnect(
                $proGetHost,
                $proGetPort,
                $null,
                $null
            )

            if ($connectAsyncResult.AsyncWaitHandle.WaitOne(3000, $false)) {
                try {
                    $tcpClient.EndConnect($connectAsyncResult)
                    $useInternalChocoSource = $true
                }
                catch {
                    Write-Warning "Failed to connect to ProGet at ${proGetHost}:$proGetPort. $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "Timed out connecting to ProGet at ${proGetHost}:$proGetPort."
            }
        }
        finally {
            if ($null -ne $connectAsyncResult) {
                $connectAsyncResult.AsyncWaitHandle.Close()
            }

            $tcpClient.Close()
            $tcpClient.Dispose()
        }
    }
}
else {
    Write-Host 'Winget was not found. WireGuard and ProGet setup will be skipped.' -ForegroundColor Yellow
}

if ($useInternalChocoSource) {
    Write-Host 'ProGet is reachable. Switching Chocolatey to the internal ProGet source...' -ForegroundColor Cyan

    & $chocoPath source remove --name $internalChocoSourceName 2>$null

    & $chocoPath source add `
        --name $internalChocoSourceName `
        --source $internalChocoSourceUrl

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'The internal Chocolatey source could not be added.' -ForegroundColor Red
        exit 1
    }

    & $chocoPath source enable --name $internalChocoSourceName
    & $chocoPath source disable --name chocolatey
}
else {
    Write-Host 'ProGet is not available over WireGuard.' -ForegroundColor Yellow
    Write-Host 'Chocolatey can continue using the public community repository.' -ForegroundColor Yellow

    do {
        $fallbackChoice = Read-Host 'Fallback to the public Chocolatey repository? (Y/N)'
    }
    while ($fallbackChoice -notin @('Y', 'y', 'N', 'n'))

    if ($fallbackChoice -in @('N', 'n')) {
        Write-Host 'Aborting per user request.' -ForegroundColor Red
        exit 1
    }

    & $chocoPath source enable --name chocolatey

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'The public Chocolatey source could not be enabled.' -ForegroundColor Red
        exit 1
    }

    & $chocoPath source disable --name $internalChocoSourceName 2>$null

    Write-Host 'Continuing with the public Chocolatey source...' -ForegroundColor Cyan
}

# ------------------------------------------------------------
# Check for Python 3.10
# ------------------------------------------------------------

$pythonPath = 'C:\Python310\python.exe'
$pythonInstalled = Test-Path -LiteralPath $pythonPath

if (-not $pythonInstalled) {
    Write-Host 'Installing Python 3.10...' -ForegroundColor Cyan

    & $chocoPath install python310 --force

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Python 3.10 installation failed.' -ForegroundColor Red
        exit 1
    }
}

# ------------------------------------------------------------
# Check for Git
# ------------------------------------------------------------

$gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue

if (-not $gitCommand) {
    Write-Host 'Installing Git...' -ForegroundColor Cyan

    & $chocoPath install git --force

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Git installation failed.' -ForegroundColor Red
        exit 1
    }

    Start-Sleep -Seconds 5
    $gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue
}

if ($gitCommand) {
    $gitPath = $gitCommand.Source
}
elseif (Test-Path -LiteralPath $gitDefaultPath) {
    $gitPath = $gitDefaultPath
}
else {
    Write-Host 'Git was installed, but git.exe could not be located.' -ForegroundColor Red
    exit 1
}

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

Write-Host '----------------------------------------------------' -ForegroundColor White -BackgroundColor Green
Write-Host ' Git Context Menu Entries Removed from the Registry ' -ForegroundColor White -BackgroundColor Green
Write-Host '----------------------------------------------------' -ForegroundColor White -BackgroundColor Green

# ------------------------------------------------------------
# Detect VMware
# ------------------------------------------------------------

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

$vmwareVm = $computerSystem.Manufacturer -eq 'VMware, Inc.'

if ($vmwareVm) {
    Write-Host '-------------------------------------------------------------' -ForegroundColor White -BackgroundColor Green
    Write-Host 'Detected VMware virtual machine. Installing VMware Tools...' -ForegroundColor White -BackgroundColor Green
    Write-Host '-------------------------------------------------------------' -ForegroundColor White -BackgroundColor Green

    & $chocoPath install vmware-tools --force
}
else {
    Write-Host '-----------------------------------------------------------------------------' -ForegroundColor White -BackgroundColor Green
    Write-Host 'Not running as a VMware virtual machine. Skipping VMware Tools installation. ' -ForegroundColor White -BackgroundColor Green
    Write-Host '-----------------------------------------------------------------------------' -ForegroundColor White -BackgroundColor Green
}

# ------------------------------------------------------------
# Detect QEMU or Proxmox virtual machines
# ------------------------------------------------------------

$qemuVm = (
    $computerSystem.Manufacturer -match 'QEMU' -or
    $computerSystem.Model -match 'Standard PC \(i440FX \+ PIIX, 1996\)' -or
    $computerSystem.Model -match 'Q35'
)

if ($qemuVm) {
    Write-Host '-------------------------------------------------------------' -ForegroundColor White -BackgroundColor Blue
    Write-Host 'Detected QEMU virtual machine. Installing QEMU Guest Agent...' -ForegroundColor White -BackgroundColor Blue
    Write-Host '-------------------------------------------------------------' -ForegroundColor White -BackgroundColor Blue

    & $chocoPath install qemu-guest-agent --force --ignore-package-exit-codes

    Write-Host '-------------------------------------------------------------------' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host 'Reminder: A system reboot is required to complete the installation.' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host 'Please plan to reboot your system after the script completes.      ' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host '-------------------------------------------------------------------' -ForegroundColor Black -BackgroundColor Yellow
}
else {
    Write-Host '------------------------------------------------------------------------------' -ForegroundColor White -BackgroundColor Blue
    Write-Host 'Not running as a QEMU virtual machine. Skipping QEMU Guest Agent installation.' -ForegroundColor White -BackgroundColor Blue
    Write-Host '------------------------------------------------------------------------------' -ForegroundColor White -BackgroundColor Blue
}

# ------------------------------------------------------------
# Clone or update the workstation-prep repository
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $repoPath)) {
    Write-Host "Cloning branch '$gitBranch' from $gitRepoUrl..." -ForegroundColor Cyan

    & $gitPath clone `
        --branch $gitBranch `
        --single-branch `
        $gitRepoUrl `
        $repoPath

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'The Git repository could not be cloned.' -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Updating branch '$gitBranch' in $repoPath..." -ForegroundColor Cyan

    Set-Location -LiteralPath $repoPath

    & $gitPath fetch origin $gitBranch

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Git fetch failed.' -ForegroundColor Red
        exit 1
    }

    & $gitPath switch $gitBranch

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Git could not switch to branch '$gitBranch'." -ForegroundColor Red
        exit 1
    }

    & $gitPath pull --ff-only origin $gitBranch

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Git pull failed.' -ForegroundColor Red
        exit 1
    }
}

# ------------------------------------------------------------
# Configure current-user Windows settings and Explorer behavior
# ------------------------------------------------------------

# Disable the Chat icon on the taskbar
$registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty `
    -Path $registryPath `
    -Name 'TaskbarMn' `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# Disable Windows consumer features
$registryPath = 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent'

if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty `
    -Path $registryPath `
    -Name 'DisableWindowsConsumerFeatures' `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# Disable suggested content and silently installed applications
$registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty `
    -Path $registryPath `
    -Name 'ContentDeliveryAllowed' `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

New-ItemProperty `
    -Path $registryPath `
    -Name 'SilentInstalledAppsEnabled' `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

New-ItemProperty `
    -Path $registryPath `
    -Name 'SystemPaneSuggestionsEnabled' `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# ------------------------------------------------------------
# Restore the classic Windows 11 right-click context menu
# ------------------------------------------------------------

$registryPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'

if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}
Set-Item -Path $registryPath -Value ''

# ------------------------------------------------------------
# Increase the mouse hover delay
# ------------------------------------------------------------

$registryPath = 'HKCU:\Control Panel\Mouse'

if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty `
    -Path $registryPath `
    -Name 'MouseHoverTime' `
    -PropertyType String `
    -Value '10000' `
    -Force | Out-Null

# ------------------------------------------------------------
# Show hidden files and file extensions for the current user
# ------------------------------------------------------------

$registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

New-ItemProperty `
    -Path $registryPath `
    -Name 'Hidden' `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

New-ItemProperty `
    -Path $registryPath `
    -Name 'HideFileExt' `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# ------------------------------------------------------------
# Create shared desktop shortcuts
# ------------------------------------------------------------

$targetPathPostUserInstall = Join-Path `
    -Path $repoPath `
    -ChildPath 'post-user-install.bat'

$iconPathPostUserInstall = Join-Path `
    -Path $repoPath `
    -ChildPath 'installme.ico'

$targetPathChocoApps = Join-Path `
    -Path $repoPath `
    -ChildPath 'chocoapps.bat'

$iconPathChocoApps = Join-Path `
    -Path $repoPath `
    -ChildPath 'installer.ico'

$sharedDesktop = [Environment]::GetFolderPath(
    [Environment+SpecialFolder]::CommonDesktopDirectory
)

if (-not (Test-Path -LiteralPath $sharedDesktop)) {
    New-Item `
        -Path $sharedDesktop `
        -ItemType Directory `
        -Force | Out-Null
}

$wshShell = New-Object -ComObject WScript.Shell

try {
    $shortcutPathPostUserInstall = Join-Path `
        -Path $sharedDesktop `
        -ChildPath 'Post User Install.lnk'

    $shortcutPostUserInstall = $wshShell.CreateShortcut(
        $shortcutPathPostUserInstall
    )

    $shortcutPostUserInstall.TargetPath = $targetPathPostUserInstall
    $shortcutPostUserInstall.WorkingDirectory = $repoPath
    $shortcutPostUserInstall.IconLocation = $iconPathPostUserInstall
    $shortcutPostUserInstall.Description = 'Shortcut to Post-User-Install Script'
    $shortcutPostUserInstall.Save()

    $shortcutPathChocoApps = Join-Path `
        -Path $sharedDesktop `
        -ChildPath 'Choco Apps.lnk'

    $shortcutChocoApps = $wshShell.CreateShortcut(
        $shortcutPathChocoApps
    )

    $shortcutChocoApps.TargetPath = $targetPathChocoApps
    $shortcutChocoApps.WorkingDirectory = $repoPath
    $shortcutChocoApps.IconLocation = $iconPathChocoApps
    $shortcutChocoApps.Description = 'Shortcut to Choco Apps Script'
    $shortcutChocoApps.Save()
}
finally {
    if ($null -ne $shortcutPostUserInstall) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject(
            $shortcutPostUserInstall
        )
    }

    if ($null -ne $shortcutChocoApps) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject(
            $shortcutChocoApps
        )
    }

    if ($null -ne $wshShell) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject(
            $wshShell
        )
    }

    Remove-Variable `
        -Name shortcutPostUserInstall `
        -ErrorAction SilentlyContinue

    Remove-Variable `
        -Name shortcutChocoApps `
        -ErrorAction SilentlyContinue

    Remove-Variable `
        -Name wshShell `
        -ErrorAction SilentlyContinue

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

# ------------------------------------------------------------
# Completion message
# ------------------------------------------------------------

$statusMessage = @"
Changes Applied:

1. File extensions are visible for the current user.
2. Hidden files are visible for the current user.
3. Windows consumer and suggested-content settings were disabled.
4. Current-user registry tweaks were applied.
5. Shared desktop shortcuts were created.
6. Chocolatey and required support applications were configured.

The Splashtop SOS download may have been skipped if No was selected.

Press Enter to acknowledge.
"@

Write-Host $statusMessage
Read-Host