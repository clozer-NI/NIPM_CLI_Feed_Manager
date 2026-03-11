# NIPM CLI Feed Manager

A collection of Windows batch files (.bat) that use the **NI Package Manager (NIPM) Command Line Interface (CLI)** to perform bulk installation and management of NI software using offline feeds, primarily from `\\argo\ni\nipkg`.

## Prerequisites

- Windows operating system
- Network access to `\\argo\ni\nipkg` (or equivalent offline feed location)
- Administrator privileges (required for install/uninstall operations)

## Batch Files

| File | Description |
|------|-------------|
| `1_Install-NIPackageManager.bat` | Silently installs NI Package Manager from the offline network share |
| `2_Browse-NI-Feeds.bat` | Lists configured feeds, available packages, and installed NI packages |
| `3_Add-MultipleFeed-Install_ALL_Feeds.bat` | Adds multiple offline feeds and installs **all** available packages |
| `4_Uninstall-NI-Packages.bat` | Uninstalls specified NI packages (or all NI software) |
| `Add-SerialFeed-Install.bat` | Adds the NI-Serial offline feed and installs NI-Serial packages |

## Usage

Run the batch files in numbered order for a full installation workflow:

1. **`1_Install-NIPackageManager.bat`** – Install NIPM first if it is not already present.
2. **`2_Browse-NI-Feeds.bat`** – Review currently configured feeds and installed packages.
3. **`3_Add-MultipleFeed-Install_ALL_Feeds.bat`** – Add all required offline feeds and perform a bulk install.
4. **`4_Uninstall-NI-Packages.bat`** – Remove packages when they are no longer needed.

Use **`Add-SerialFeed-Install.bat`** independently to add and install NI-Serial support.

## Customization

- Edit the feed paths inside each `.bat` file to match your network layout.
- In `4_Uninstall-NI-Packages.bat`, update the `PACKAGES_TO_REMOVE` variable with the exact package names reported by `nipkg list-installed`.
- In `3_Add-MultipleFeed-Install_ALL_Feeds.bat`, add or remove `feed-add` lines to match the feeds available in your environment.

## NI Package Manager CLI Reference

The CLI executable is located at:
```
C:\Program Files\National Instruments\NI Package Manager\nipkg.exe
```

Common commands used by these scripts:

| Command | Description |
|---------|-------------|
| `nipkg feed-add --name="<name>" "<path>"` | Register an offline feed |
| `nipkg feed-update` | Refresh feed metadata |
| `nipkg feed-list` | List all configured feeds |
| `nipkg list` | List all available packages |
| `nipkg list-installed` | List installed packages |
| `nipkg install --yes --accept-eulas <pkg>` | Install a package silently |
| `nipkg remove --allow-uninstall --yes <pkg>` | Remove a specific package |

For full documentation see the [NI Package Manager CLI reference](https://www.ni.com/docs/en-US/bundle/package-manager/page/cli-package-manager.html).
