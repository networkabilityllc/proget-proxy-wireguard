import tkinter as tk
from tkinter import ttk
import subprocess
import os

# Dictionary mapping official names to package names
software_mapping = {
    "7zip": "7-Zip",
    "adobereader": "Adobe Reader",
    "amd-ryzen-chipset": "AMD Ryzen Chipset Drivers",
    "ccleaner": "CCleaner",
    "chocolateygui": "Chocolatey GUI",
    "choco-upgrade-all-at": "Chocolatey Nightly Upgrade",
    "cpu-z": "CPU-Z",
    "duf": "Disk Usage/Free Utility",
    "supportassist": "Dell SupportAssist",
    "ditto": "Ditto Clipboard Manager",
    "dotnet": ".NET Framework",
    "dotnetfx": ".NET Framework 4.8",
    "etcher": "balenaEtcher",
    "everything": "Everything File Search",
    "firefox": "Firefox",
    "flow-launcher": "Flow Launcher",
    "gawk": "Gawk",
    "googlechrome": "Google Chrome",
    "hwinfo": "HWiNFO",
    "intel-dsa": "Intel Driver Support Assistant",
    "iperf3": "iPerf3",
    "javaruntime": "Java Runtime",
    "libreoffice-fresh": "LibreOffice Fresh",
    "lightshot": "Lightshot Screen Capture",
    "linkshellextension" : "Link Shell Extension",
    "microsoft-edge": "Microsoft Edge",
    "mobaxterm": "MobaXterm",
    "mremoteng": "mRemoteNG",
    "naps2": "NAPS2",
    "nssm": "NSSM - Non-Sucky Service Manager",
    "notepadplusplus": "Notepad++",
    "open-shell": "Open-Shell",
    "openjdk": "OpenJDK",
    "openssl": "OpenSSL",
    "partitionwizard": "MiniTool Partition Wizard",
    "powershell-core": "PowerShell 7.x",
    "powertoys": "PowerToys",
    "QEMU Guest Agent": "QEMU Guest Agent",
    "sed": "Sed",
    "speccy": "Speccy",
    "sysinternals": "Sysinternals Suite",
    "tightvnc": "TightVNC Server",
    "translucenttb": "TranslucentTB",
    "vcredist-all": "Visual C++ Redistributable",
    "vlc": "VLC Media Player",
    "microsoft-windows-terminal": "Windows Terminal",
    "WireGuard": "WireGuard",
    "zoom": "Zoom"
}

# List of software items and their installation parameters
software_items = [
    ("7zip", ["--force"]),
    ("adobereader", ["--force", "--params", "/DesktopIcon"]),
    ("amd-ryzen-chipset", ["--force"]),
    ("ccleaner", ["--force"]),
    ("choco-upgrade-all-at", ["--force"]),
    ("chocolateygui", ["--force"]),
    ("cpu-z", ["--force"]),
    ("duf", ["--force"]),
    ("etcher", ["--force"]),
    ("supportassist", ["--force"]),
    ("ditto", ["--force"]),
    ("dotnet", ["--force"]),
    ("dotnetfx", ["--force"]),
    ("everything", ["--force"]),
    ("firefox", ["--force"]),
    ("flow-launcher", ["--force"]),
    ("gawk", ["--force"]),
    ("googlechrome", ["--force"]),
    ("hwinfo", ["--force"]),
    ("intel-dsa", ["--force", "--ignore-checksums"]),
    ("iperf3", ["--force"]),
    ("javaruntime", ["--force"]),
    ("libreoffice-fresh", ["--force"]),
    ("lightshot", ["--force"]),
    ("linkshellextension", ["--force"]),
    ("microsoft-edge", ["--force"]),
    ("mobaxterm", ["--force"]),
    ("mremoteng", ["--force"]),
    ("naps2", ["--force"]),
    ("nssm", ["--force"]),
    ("notepadplusplus", ["--force"]),
    ("open-shell", ["--params=\"/StartMenu\""]),
    ("openjdk", ["--force"]),
    ("openssl", ["--force"]),
    ("partitionwizard", ["--force"]),
    ("powershell-core", ["--force"]),
    ("powertoys", ["--force"]),
    ("qemu-guest-agent", ["--force"]),
    ("sed", ["--force"]),    
    ("speccy", ["--force", "--ignore-checksums"]),
    ("sysinternals", ["-y"]),
    ("tightvnc", ["-y", "--installArguments", "\"SET_RUNCONTROLINTERFACE=1 VALUE_OF_RUNCONTROLINTERFACE=0 SET_DISCONNECTACTION=1 VALUE_OF_DISCONNECTACTION=1 SET_USEVNCAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=0 SET_ALLOWLOOPBACK=1 VALUE_OF_ALLOWLOOPBACK=1 SET_REMOVEWALLPAPER=1 VALUE_OF_REMOVEWALLPAPER=0 SET_LOCKDESKTOP=1\""]),
    ("translucenttb", ["--force", "--ignore-checksums"]),
    ("vcredist-all", ["--force"]),
    ("vlc", ["--force"]),
    ("microsoft-windows-terminal", ["--force"]),
    ("WireGuard", ["--force"]),
    ("zoom", ["--force"])
]

choco_path = r'c:\ProgramData\chocolatey\choco.exe'  # Chocolatey path
powershell_path = r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

# Chris Titus Tech WinUtil presets.
# The valid preset names are Advanced, Standard, and Minimal.
ctt_presets = {
    "Advanced": "Advanced",
    "Standard": "Standard",
    "Minimal": "Minimal"
}


# Function to refresh checkboxes in both tabs
def refresh_checkboxes():
    check_and_update_text_color_and_checkbox_state_install(checkboxes_tab1)
    check_and_update_text_color_and_checkbox_state(checkboxes_tab2)

# Function to install or uninstall selected software based on the tab
def install_or_uninstall(tab):
    action = "install" if tab == tab1 else "uninstall"
    checkboxes_to_use = checkboxes_tab1 if tab == tab1 else checkboxes_tab2
    for package_name, params, var, checkbox in checkboxes_to_use:
        if var.get():
            if action == "uninstall":
                # Check if the package is a meta package
                is_meta_package = check_if_meta_package(package_name)
                if is_meta_package:
                    # If it's a meta package, uninstall the package and its dependencies
                    uninstall_meta_package(package_name)
                else:
                    # If it's not a meta package, uninstall the package only
                    uninstall_package(package_name, params)
                # After uninstallation, change the text color to green and refresh checkboxes
                checkbox.configure(fg="green")
                var.set(0)  # Clear the checkbox after successful uninstallation
                refresh_checkboxes()
            else:
                # Handle installation here
                install_package(package_name, params)
                # After installation, change the text color to green, clear the checkbox, and refresh checkboxes
                checkbox.configure(fg="green")
                var.set(0)  # Clear the checkbox after successful installation
                refresh_checkboxes()

# Function to check if a package is a meta package using 'choco list'
def check_if_meta_package(package_name):
    result = subprocess.run([choco_path, "list", package_name], stdout=subprocess.PIPE, text=True)
    if result.returncode == 0:
        # Check if the output contains multiple lines (indicating a meta package)
        return len(result.stdout.split("\n")) > 1
    return False

# Function to uninstall a meta package and its dependencies
def uninstall_meta_package(package_name):
    try:
        # Check if it's a meta package
        if check_if_meta_package(package_name):
            # Use 'choco uninstall' with the '--yes' flag to uninstall the package and its dependencies
            subprocess.run([choco_path, "uninstall", package_name, package_name + ".install", "--yes"])
    except Exception as e:
        print(f"Error uninstalling {package_name} meta package: {e}")

# Function to uninstall a single package
def uninstall_package(package_name, params):
    try:
        # Use 'choco uninstall' with the '--yes' flag to uninstall the package
        subprocess.run([choco_path, "uninstall", package_name, "--yes"])
    except Exception as e:
        print(f"Error uninstalling {package_name}: {e}")

# Function to install a single package
def install_package(package_name, params):
    try:
        # Use 'choco install' with the parameters
        subprocess.run([choco_path, "install", package_name] + params)
    except Exception as e:
        print(f"Error installing {package_name}: {e}")

# Function to run a Chris Titus Tech WinUtil preset
def run_ctt_preset():
    preset = ctt_preset_var.get()

    if preset not in ctt_presets:
        ctt_status_label.configure(text="Select a valid CTT preset.")
        return

    ctt_status_label.configure(text=f"Running CTT {preset} preset...")
    root.update_idletasks()

    powershell_command = (
        "$winUtilScript = Invoke-RestMethod -Uri 'https://christitus.com/win'; "
        f"& ([ScriptBlock]::Create($winUtilScript)) -Preset '{preset}'"
    )

    try:
        result = subprocess.run(
            [
                powershell_path,
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-Command",
                powershell_command
            ],
            check=False
        )

        if result.returncode == 0:
            ctt_status_label.configure(
                text=f"CTT {preset} preset completed successfully."
            )
        else:
            ctt_status_label.configure(
                text=f"CTT {preset} preset exited with code {result.returncode}."
            )
    except Exception as e:
        ctt_status_label.configure(text=f"Error running CTT preset: {e}")
        
# Function to check and update text color and checkbox state based on installation status for the install tab
def check_and_update_text_color_and_checkbox_state_install(checkbox_list):
    installed_packages = get_installed_packages()
    for package_name, _, _, checkbox in checkbox_list:
        # Check for partial and case-insensitive matches
        if any(package_name.lower() in installed.lower() for installed in installed_packages):
            # Package is installed, set text color to green in the install tab
            checkbox.configure(fg="green", state=tk.NORMAL)
        else:
            # Package is not installed, set text color to black and enable the checkbox in the install tab
            checkbox.configure(fg="black", state=tk.NORMAL)


# Function to check and update text color and checkbox state based on installation status for the uninstall tab
def check_and_update_text_color_and_checkbox_state(checkbox_list):
    installed_packages = get_installed_packages()
    for package_name, _, _, checkbox in checkbox_list:
        # Check for partial and case-insensitive matches
        if any(package_name.lower() in installed.lower() for installed in installed_packages):
            # Package is installed, set text color to green in the uninstall tab
            checkbox.configure(fg="green", state=tk.NORMAL)
        else:
            # Package is not installed, set text color to black and disable the checkbox in the uninstall tab
            checkbox.configure(fg="black", state=tk.DISABLED)

# Function to get a list of installed packages using 'choco list'
def get_installed_packages():
    result = subprocess.run([choco_path, "list"], stdout=subprocess.PIPE, text=True)
    if result.returncode == 0:
        installed_packages = []
        lines = result.stdout.split("\n")
        for line in lines:
            parts = line.strip().split(" ")
            if len(parts) > 1:
                installed_packages.append(parts[0])
        return installed_packages
    else:
        return []

# Create the main window
root = tk.Tk()
root.title("NetworkAbility Software Installer")

# Create a Tab Control widget
tabControl = ttk.Notebook(root)

# Create tabs for installation, uninstallation, and CTT presets
tab1 = ttk.Frame(tabControl)
tab2 = ttk.Frame(tabControl)
tab3 = ttk.Frame(tabControl)

# Add the tabs to the Tab Control widget with specified text labels
tabControl.add(tab1, text='Install')
tabControl.add(tab2, text='Uninstall')
tabControl.add(tab3, text='CTT Presets')

# Make the Tab Control widget expand to fill the available space in the main window
tabControl.pack(expand=1, fill="both")

# Create a label for the message in each tab
message_label1 = tk.Label(tab1, text="Applications in Green have already been installed by Chocolatey")
message_label1.pack(padx=10, pady=10)

message_label2 = tk.Label(tab2, text="Applications that are grayed out were not installed by Chocolatey and cannot be uninstalled")
message_label2.pack(padx=10, pady=10)

message_label3 = tk.Label(
    tab3,
    text="Select one Chris Titus Tech WinUtil preset. These presets run without further interaction."
)
message_label3.pack(padx=10, pady=10)

# Create a frame for the checkboxes in each tab
checkbox_frame1 = tk.Frame(tab1)
checkbox_frame1.pack(padx=10, pady=10)

checkbox_frame2 = tk.Frame(tab2)
checkbox_frame2.pack(padx=10, pady=10)

# Organize checkboxes into columns in each tab
num_columns = 3
checkboxes_tab1 = []
checkboxes_tab2 = []

# Create checkboxes for all software items for both tabs
for i, (package_name, params) in enumerate(software_items):
    var1 = tk.IntVar()
    var2 = tk.IntVar()
    official_name = software_mapping.get(package_name, package_name)  # Get the official name or use the package name
    
    checkbox1 = tk.Checkbutton(checkbox_frame1, text=official_name, variable=var1)
    checkbox2 = tk.Checkbutton(checkbox_frame2, text=official_name, variable=var2)
    
    row = i // num_columns
    column = i % num_columns
    
    checkbox1.grid(row=row, column=column, sticky="w", padx=5, pady=5)
    checkbox2.grid(row=row, column=column, sticky="w", padx=5, pady=5)
    
    checkboxes_tab1.append((package_name, params, var1, checkbox1))
    checkboxes_tab2.append((package_name, params, var2, checkbox2))

# Check and update text color and checkbox state based on installation status for the install tab
check_and_update_text_color_and_checkbox_state_install(checkboxes_tab1)

# Check and update text color and checkbox state based on installation status for the uninstall tab
check_and_update_text_color_and_checkbox_state(checkboxes_tab2)

# Create install/uninstall buttons in each tab
install_button1 = tk.Button(tab1, text="Install Selected", command=lambda: install_or_uninstall(tab1))
install_button1.pack(pady=10)

install_button2 = tk.Button(tab2, text="Uninstall Selected", command=lambda: install_or_uninstall(tab2))
install_button2.pack(pady=10)

# Create mutually exclusive CTT preset choices
ctt_preset_var = tk.StringVar(value="Standard")

ctt_preset_frame = tk.Frame(tab3)
ctt_preset_frame.pack(padx=10, pady=10)

for preset_name in ctt_presets:
    preset_button = tk.Radiobutton(
        ctt_preset_frame,
        text=f"CTT {preset_name}",
        variable=ctt_preset_var,
        value=preset_name
    )
    preset_button.pack(anchor="w", padx=5, pady=5)

ctt_run_button = tk.Button(
    tab3,
    text="Run Selected CTT Preset",
    command=run_ctt_preset
)
ctt_run_button.pack(pady=10)

ctt_status_label = tk.Label(tab3, text="")
ctt_status_label.pack(padx=10, pady=10)

# Function to exit the application
def exit_app():
    root.destroy()
    os._exit(0)  # Close the console window

# Create exit buttons in each tab
exit_button1 = tk.Button(tab1, text="Exit", command=exit_app)
exit_button1.pack(pady=10)

exit_button2 = tk.Button(tab2, text="Exit", command=exit_app)
exit_button2.pack(pady=10)

exit_button3 = tk.Button(tab3, text="Exit", command=exit_app)
exit_button3.pack(pady=10)

# Start the main event loop
root.mainloop()
