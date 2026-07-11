## Disclaimer

This is a highly opinionated installation script that does exactly what I want for new workstation installs. Some features may not be desirable to you, however everything is done by batch file, PowerShell script, and Python, and all of the code is commented and should be easily modifiable.

# Workstation Preparation Script (workstationprep.ps1)
This PowerShell script, `workstationprep.ps1`, automates the process of preparing a Windows workstation for a new user. It performs various tasks to set up the workstation environment efficiently.

## How to Use

### Method 1: Run Directly from GitHub

On new installs, I execute the Workstation Prep Script from Audit Mode.
At first boot, when presented with the Language selection, press SHFT-CTRL-F3 and 
windows will reboot to Audit Mode.
I suggest you run both the workstation script and the post-user install script while in Audit Mode

I also generally reboot into OOBE, and then press SHFT-F10 and in the command prompt window type in 
```cmd
oobe\bypassnro
```

This will reboot into OOBE without the requirement for setting up an online account

If you're comfortable running the script directly from GitHub, you can use the following command to execute it:

```powershell
iwr -useb https://raw.githubusercontent.com/networkabilityllc/proget-proxy-wireguard/main/workstationprep.ps1 | iex
```

### Method 2: Clone and Run Manually

Alternatively, you can clone the repository and run the script manually. Here are the steps:

1. Clone the repository to your local machine. These scripts expect to be run from `C:\Prep`, so first create that folder, then change to it and run:

   ```bash
   git clone https://github.com/networkabilityllc/proget-proxy-wireguard.git
   ```

2. Navigate to the cloned repository directory.

   ```bash
   cd proget-proxy-wireguard
   ```

3. Before running the script, set the execution policy to Bypass for LocalMachine. This is required to ensure the script can run without restrictions. Run the following command:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope LocalMachine -Force
   ```

4. Run the script.

   ```powershell
   .\workstationprep.ps1
   ```

5. After the script has completed its tasks, you can reset the execution policy to its default value for security reasons. Run the following command:

   ```powershell
   Set-ExecutionPolicy Default
   ```

This sequence of steps ensures that you temporarily set the execution policy to Bypass for LocalMachine before running the script and then reset it to Default afterward for security purposes.


## Script Overview

The `workstationprep.ps1` script performs the following tasks:

1. Creates a directory on the new workstation at `C:\prep`.

2. Sets the execution policy to `Bypass` locally to ensure that built-in scripts run properly.

3. Prompts the installer if they want to Download SplashtopSOS to the `C:\Users\Default\Desktop` location, making it available on new user desktops.

4. Checks for and installs Chocolatey and Boxstarter if they are not already installed.

5. Checks for the existence of Python 3.10 and installs it if necessary.

6. Checks for the existence of Git and installs it if necessary. Removes Git context menu options.

7. Detects if the machine is a VMware virtual machine and installs the latest VMware Tools if applicable.

8. Clones the repository into `C:\prep`, creating a folder called `proget-proxy-wireguard`.

9. Connects the local session to the ProGet Proxy server via WireGuard profile

10. Disables Bing Search, GameBar Tips, and enables Show Hidden Files and Folders with Show File Extensions.

11. Turns off most Windows telemetry for the user.

12. Restores the classic right-click context menu.

13. Sets the mouse hover time for the taskbar to a very long time, effectively disabling hover text and thumbnails.

14. Creates a shortcut to `post-user-install.bat` as "C:\Users\Default\Desktop\Post User Install.lnk" for easy setup of new user actions.

15. Displays a summary of the performed actions, waits for user confirmation, and exits.

Feel free to customize and use this script according to your workstation preparation needs.

## License

This script is provided under the [MIT License](LICENSE). See the [LICENSE](LICENSE) file for details.

---