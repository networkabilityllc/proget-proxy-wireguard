# NetworkAbility Workstation Preparation — Tech Desk Edition

> **Internal technician deployment variant**
>
> This repository is intended for NetworkAbility Tech Desk use. It is **not a standalone public workstation-preparation package** and is not expected to work as designed outside the NetworkAbility deployment environment.
>
> The general-purpose/public version of these scripts is maintained separately in [NewWindowsScripts](https://github.com/networkabilityllc/NewWindowsScripts).

## Purpose

This repository contains the NetworkAbility workstation-preparation workflow used by technicians when staging Windows systems.

It extends the public `NewWindowsScripts` workflow with NetworkAbility-specific infrastructure, including:

- a private Chocolatey package cache/proxy hosted in ProGet;
- WireGuard connectivity to the private ProGet service;
- automatic selection of the internal Chocolatey source when ProGet is reachable;
- technician-oriented bootstrap and post-user configuration scripts;
- a local post-user configuration workflow rather than downloading the configuration script from GitHub each time;
- a Chocolatey application installer with optional Chris Titus Tech WinUtil presets.

The scripts are intentionally opinionated and are designed around the NetworkAbility workstation-build process.

## Important: Required Internal Components

The GitHub repository does **not** contain everything required for the internal workflow.

The technician environment is expected to provide:

```text
C:\prep\wg\tech.conf
```

This WireGuard configuration is intentionally maintained outside the repository.

The current scripts expect the internal ProGet service to be reachable through the WireGuard tunnel at the configured private address and port. If the tunnel or ProGet service is unavailable, `workstationprep.ps1` can offer to fall back to the public Chocolatey community source.

Do not commit WireGuard private keys, technician tunnel configurations, credentials, or other deployment secrets to this repository.

## Public vs. Tech Desk Repositories

### `NewWindowsScripts`

[NewWindowsScripts](https://github.com/networkabilityllc/NewWindowsScripts) is the general-purpose/public development branch of the workstation-preparation scripts.

It does not depend on NetworkAbility's private ProGet service or technician WireGuard configuration.

### `proget-proxy-wireguard`

This repository is the NetworkAbility Tech Desk deployment variant.

It assumes the technician has access to the supporting NetworkAbility infrastructure and uses the internal package path when that infrastructure is available.

Because those private dependencies are not included in GitHub, cloning this repository by itself does not reproduce the complete NetworkAbility deployment environment.

## Deployment Workflow

### 1. Enter Windows Audit Mode

On a new Windows installation, at the initial language/OOBE screen, press:

```text
CTRL+SHIFT+F3
```

Windows will reboot into Audit Mode.

The workstation-preparation phase is normally run from Audit Mode so that machine-level configuration and shared desktop items can be established before the end user is created.

### 2. Prepare technician files

Before running the internal workflow, make sure the required technician-side files are present under `C:\prep`.

At minimum, the WireGuard configuration expected by the current script is:

```text
C:\prep\wg\tech.conf
```

If the target system does not have Winget available, the current script instructs the technician to install Winget using the separate Tech USB workflow before rerunning workstation preparation.

### 3. Run `workstationprep.ps1`

Run from an elevated PowerShell session:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\workstationprep.ps1
```

`workstationprep.ps1` is the initial machine-preparation script.

The current workflow:

1. Creates and uses `C:\prep`.
2. Optionally downloads Splashtop SOS to the shared/default-user desktop.
3. Verifies Chocolatey and installs it with Winget if Chocolatey is not already present.
4. Enables Chocolatey global confirmation.
5. Installs or updates WireGuard through Winget.
6. Loads the technician WireGuard configuration from `C:\prep\wg\tech.conf`.
7. Starts the WireGuard tunnel and tests connectivity to the internal ProGet service.
8. Configures Chocolatey to use the internal ProGet-backed feed when ProGet is reachable.
9. Offers a fallback to the public Chocolatey community repository when the internal service is unavailable.
10. Installs Python 3.10 and Git as needed.
11. Removes Git shell/context-menu entries that are unnecessary on deployed workstations.
12. Detects VMware and QEMU/Proxmox virtual machines and installs the corresponding guest tools where applicable.
13. Clones or updates this repository under:

```text
C:\prep\proget-proxy-wireguard
```

14. Applies baseline current-user Windows configuration.
15. Creates shared desktop shortcuts for post-user configuration and the Chocolatey application installer.

## Chocolatey and ProGet

The current implementation uses Chocolatey normally on the workstation, but changes its package source when the NetworkAbility ProGet service is available.

The configured internal source is a Chocolatey/NuGet-compatible feed hosted by ProGet.

When internal connectivity is available, the workflow:

1. removes any stale definition of the internal source;
2. adds the configured ProGet feed;
3. enables the internal source; and
4. disables the normal Chocolatey community source.

If ProGet cannot be reached, the script prompts the technician before enabling the public Chocolatey source and continuing.

### Chocolatey bootstrap note

In the current version of `workstationprep.ps1`, **Chocolatey itself is installed through Winget** when it is missing.

The ProGet `/nuget/choco` endpoint is then used as the Chocolatey package source. It is a NuGet-compatible feed, but the current script does not use `nuget.exe` to bootstrap Chocolatey.

## Post-User Configuration

After the intended Windows user has logged on, run the **Post User Install** shortcut created during preparation.

`Post-User-Install.bat` elevates and launches the local copy of:

```text
C:\prep\proget-proxy-wireguard\configure.ps1
```

Unlike the older/public workflow, the Tech Desk version does not need to download `configure.ps1` from the raw GitHub URL each time.

`configure.ps1` handles the user/session configuration phase, including items such as:

- UAC configuration;
- Bing/Search settings;
- Game Bar/Game DVR settings;
- Explorer options;
- taskbar configuration;
- Windows consumer/suggested-content settings;
- classic Windows 11 context-menu behavior;
- mouse-hover timing;
- Command Prompt/PowerShell context-menu additions;
- Num Lock configuration;
- removal of Git context-menu entries;
- Microsoft VCLibs/XAML framework installation;
- hibernation and Sleep-menu configuration;
- launching the Chocolatey application installer;
- prompting whether UAC should be re-enabled when configuration is complete.

## Chocolatey Application Installer

`install_apps.py` provides the technician-facing GUI for installing and uninstalling selected Chocolatey packages.

The Tech Desk version also contains a **CTT Presets** tab for running supported Chris Titus Tech WinUtil presets:

- Advanced
- Standard
- Minimal

The preset is launched through PowerShell from the installer GUI.

## Repository Files

| File | Purpose |
|---|---|
| `workstationprep.ps1` | Initial workstation/Audit Mode preparation and internal package-source setup. |
| `configure.ps1` | Post-user Windows configuration and application-installer launch. |
| `Post-User-Install.bat` | Elevates and launches the local `configure.ps1`. |
| `chocoapps.bat` | Updates the local repository and launches `install_apps.py`. |
| `install_apps.py` | GUI for Chocolatey installs/uninstalls and CTT WinUtil presets. |
| `addprompts.reg` | Adds Command Prompt/PowerShell context-menu entries used by the configuration workflow. |
| `toggle-uac.ps1` | UAC helper script. |
| `installer.ico` | Icon used for the application-installer shortcut. |
| `installme.ico` | Icon used for the post-user-install shortcut. |
| `.gitattributes` | Repository line-ending rules. |

## OOBE Notes

After Audit Mode preparation, the system can be returned to OOBE as required by the deployment process.

Where applicable to the Windows build being deployed, the technician may use the supported OOBE workflow for creating the required local or organizational account.

The OOBE procedure is intentionally kept separate from the private ProGet/WireGuard configuration described above.

## Development Notes

The public and Tech Desk repositories have diverged substantially and should not be treated as interchangeable copies.

Changes made to `NewWindowsScripts` should be reviewed before being ported here because the Tech Desk version has additional assumptions around:

- repository paths;
- package sources;
- WireGuard;
- ProGet availability;
- fallback behavior;
- post-user execution;
- Windows configuration that has replaced older Boxstarter functions.

Likewise, changes made here may not be suitable for the public repository because the private infrastructure dependencies are deliberately absent there.

## Sensitive Information

Before committing changes, verify that the repository does not contain:

- WireGuard private keys;
- `tech.conf` or equivalent tunnel configurations;
- ProGet credentials or API keys;
- customer-specific credentials;
- unattended-install credentials;
- technician secrets.

Private addressing and service locations may be present in the deployment scripts as operational configuration, but authentication material should remain outside GitHub.
