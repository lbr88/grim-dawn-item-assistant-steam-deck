# Setup guide

This guide targets the Steam edition of Grim Dawn on Steam Deck/SteamOS. It deliberately separates one-time Item Assistant configuration from the final combined runtime.

For a no-typing setup, download `Install-Grim-Dawn-Item-Assistant.desktop` from the repository, move it to the Desktop, and double-click it. The guided installer performs these same steps with KDE dialogs. The sections below document the manual process and exactly what the wizard changes.

## Before you begin

Back up:

- Grim Dawn saves.
- Item Assistant data, if it already exists.
- Any custom Steam launch options you want to keep.

Item Assistant data normally lives at:

```text
~/.local/share/Steam/steamapps/compatdata/219990/pfx/drive_c/users/steamuser/AppData/Local/EvilSoft/IAGD
```

Never upload that directory, `userdata.db`, `settings.json`, your Item Assistant account address, or `cloudAuthToken` to a public issue or repository.

## 1. Prepare Grim Dawn and Proton

1. In Steam, open **Grim Dawn → Properties → Compatibility**.
2. Select official **Proton 10.0**.
3. Leave **Launch Options** empty.
4. Launch Grim Dawn once, reach the menu, and exit normally. This creates prefix `219990`.
5. Keep Grim Dawn closed during the rest of the one-time setup.

The standard internal-storage locations are:

```text
Game:   ~/.local/share/Steam/steamapps/common/Grim Dawn
Prefix: ~/.local/share/Steam/steamapps/compatdata/219990/pfx
```

If Steam or Grim Dawn is in a different library, the repository scripts accept environment overrides. For example:

```bash
STEAM_ROOT=/path/to/Steam \
GRIM_DAWN_DIR='/path/to/SteamLibrary/steamapps/common/Grim Dawn' \
./scripts/link-steam-detection.sh
```

## 2. Install Protontricks

Install **Protontricks** from Discover in Desktop Mode. Its upstream project recommends the Flatpak package for Steam Deck.

The Flatpak is used only for installing Windows components and opening Item Assistant by itself during configuration. Do not use it as the everyday runtime launcher: a Flatpak-launched Item Assistant cannot inject into a game in Steam's separate runtime container.

## 3. Download official installers

Download these from their official sites:

- [Grim Dawn Item Assistant](https://grimdawn.evilsoft.net/)
- [.NET Desktop Runtime for Windows x64](https://dotnet.microsoft.com/download/dotnet/)
- [Microsoft Edge WebView2 Runtime for Windows x64](https://developer.microsoft.com/microsoft-edge/webview2/)

The tested installation used Item Assistant `1.5.9700.13021`, .NET Desktop Runtime `10.0.11`, and WebView2 `151.0.4129.93`. New Item Assistant releases may change their runtime requirements; check upstream release notes.

This repository intentionally does not download or redistribute those binaries.

## 4. Install the Windows components into prefix 219990

From this repository directory, pass the three downloaded installers to:

```bash
./scripts/install-windows-components.sh \
  ~/Downloads/GDItemAssistant.exe \
  ~/Downloads/windowsdesktop-runtime-10-x64.exe \
  ~/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
```

The script copies them into Grim Dawn's compatdata directory, then installs Visual C++ 2013, the selected .NET Desktop Runtime, WebView2, and Item Assistant with Protontricks.

If an installer has a different filename, use its actual path. Paths containing spaces are supported.

## 5. Make Linux Steam detectable inside the prefix

Item Assistant expects Windows Steam at `C:\Program Files (x86)\Steam`. Its Wine file selector was unusable on the tested Deck, so the helper creates two narrowly scoped symlinks: the real Linux Steam `config.vdf` and the real Grim Dawn game directory.

For the standard internal library:

```bash
./scripts/link-steam-detection.sh
```

For a game on another Steam library:

```bash
GRIM_DAWN_DIR='/run/media/deck/CARD/steamapps/common/Grim Dawn' \
./scripts/link-steam-detection.sh
```

The script refuses to replace a real file or directory at either destination.

## 6. Parse and configure Item Assistant before the game

Keep Grim Dawn closed and run:

```bash
./scripts/run-ia-setup.sh
```

This configuration launcher does two important things:

- Starts from `C:\Program Files\IAGD`, where the hook DLL actually lives.
- Points WebView2 directly to the installed runtime version.

In Item Assistant:

1. Confirm it detects Grim Dawn.
2. Open the Grim Dawn/database area and let the initial database parse finish.
3. Restart Item Assistant once and verify that the database remains parsed.
4. Sign into Item Assistant online sync if you want the inventory from another PC.
5. Use the same Item Assistant account as the Windows machine.
6. Wait for the initial item download to finish and confirm the expected count.
7. Close Item Assistant completely.

Item Assistant online sync is not Steam Cloud. Treat its token as a password.

## 7. Install the combined Steam runtime

Run:

```bash
./scripts/install-compatibility-tool.sh
```

The installer:

- Copies only this project's three compatibility-tool files.
- Links to the existing official Proton 10 runtime instead of copying or modifying it.
- Moves an older copy to a timestamped backup rather than deleting it.
- Does not edit Steam's `config.vdf`.

Then:

1. Fully exit and restart Steam.
2. Open **Grim Dawn → Properties → Compatibility**.
3. Force **GD Item Assistant - Proton 10**.
4. Confirm Grim Dawn's **Launch Options** remain empty.

## 8. Test in Desktop Mode

1. Launch only the official **Grim Dawn** Steam entry.
2. Item Assistant should appear first.
3. About 15 seconds later, Grim Dawn should start and render normally.
4. Enter a character. A stash/injection warning while still at the main menu can be normal.
5. Put one expendable test item in the last shared-stash tab.
6. Close the stash and move the character away from it.
7. Confirm the item disappears from the stash and appears in Item Assistant.
8. Exit Grim Dawn normally; Item Assistant should close automatically.

If that passes, repeat the same test in Gaming Mode. You still launch only the official Grim Dawn entry.

## 9. Normal operation

- Last shared-stash tab: import items into Item Assistant.
- Second-to-last shared-stash tab: receive items transferred back to the game.
- Close the stash and walk away after placing import items.
- Use Steam's window switcher if you need the Item Assistant UI in Gaming Mode.

Run the read-only diagnostic at any time:

```bash
./scripts/diagnose.sh
```

## Disable or roll back

First set Grim Dawn back to official Proton 10 (or clear the forced compatibility tool) in Steam. Fully exit Steam, then run:

```bash
./scripts/uninstall-compatibility-tool.sh
```

The script moves the custom tool outside Steam's compatibility-tools directory; it does not delete it. It prints both the saved location and the path needed to restore it.

Disabling this launcher does not remove Item Assistant or its data from prefix `219990`. Deleting or recreating that prefix does.
