# Troubleshooting

Start with the read-only diagnostic:

```bash
./scripts/diagnose.sh
```

The runtime launcher log contains no cloud token and is stored at:

```text
~/.local/state/gdia-steam-deck/launch.log
```

Do not upload raw Item Assistant settings, databases, the entire Proton prefix, Steam `config.vdf`, or unfiltered Item Assistant logs. They can contain account details or credentials.

## Item Assistant opens, but Grim Dawn never starts

This usually means Item Assistant was launched separately before Steam. Proton's `waitforexitandrun` can then wait for the already-running prefix indefinitely.

1. Close Item Assistant completely.
2. Force-stop the stuck Grim Dawn session in Steam if necessary.
3. Confirm Grim Dawn uses **GD Item Assistant - Proton 10** and has empty Launch Options.
4. Launch only the official Grim Dawn entry. The custom tool starts Item Assistant itself.

## Grim Dawn opens as a black window

Remove old combined batch, VBScript, or shell launch options. They were tested and rejected because the injector could connect while the game still rendered as a black 1280×800 window.

The supported configuration is:

- Empty Grim Dawn Launch Options.
- **GD Item Assistant - Proton 10** selected under Compatibility.
- Launch the official Grim Dawn entry only.

## `Could not write any bytes into the PID address space`

Item Assistant and Grim Dawn are in separate runtime containers.

- Do not run Item Assistant through Flatpak Protontricks during gameplay.
- Do not launch a separate non-Steam Item Assistant shortcut.
- Restart Steam after installing the custom compatibility tool.
- Re-select **GD Item Assistant - Proton 10** for Grim Dawn.

## `Stash: Error` or `still in the menu`

The hook deliberately unloads or aborts while Grim Dawn is still at the main menu. Enter a character before deciding injection failed.

Once in the world, open the shared stash, put a test item in the last tab, close the stash, and walk away. If it still fails, inspect the launcher log and Item Assistant's own on-screen diagnostics.

## Items remain in the stash

Import is not triggered merely by placing an item:

1. Use the final shared-stash tab.
2. Close the stash window.
3. Move the character away from the stash area.
4. Give Item Assistant a moment to process the change.

Items sent from Item Assistant back to Grim Dawn appear in the second-to-last shared-stash tab.

## The database folder selector cannot be clicked

Close Grim Dawn and Item Assistant, then run:

```bash
./scripts/link-steam-detection.sh
./scripts/run-ia-setup.sh
```

The first helper links only the Linux Steam config and Grim Dawn installation into the Windows Steam tree Item Assistant expects. It avoids the Wine folder selector entirely.

## `ItemAssistantHook_x64.dll` is missing from a `Z:` path

Item Assistant was started with the wrong working directory. Use `scripts/run-ia-setup.sh` for configuration and the custom compatibility tool for normal play. Both start it from the installed `IAGD` directory.

## WebView2 runtime not found

Run `scripts/diagnose.sh`. If the WebView2 check fails, run `scripts/ensure-windows-components.sh`. It checks every component and downloads only the missing x64 Evergreen WebView2 Runtime into prefix `219990`.

The launch scripts select the installed WebView2 version dynamically. Do not paste the tested version number into a local launcher.

## The installer asks for Windows installer files

That was behavior in the original installer and is no longer expected. The current installer downloads missing components automatically and never presents file pickers. Rerun the downloaded desktop launcher so it fetches the current repository scripts.

## Steam remains on Running after the game exits

The wrapper normally closes Item Assistant when Grim Dawn exits. Check the final lines of:

```text
~/.local/state/gdia-steam-deck/launch.log
```

If Item Assistant ignored `taskkill`, use Steam's force-stop action once. Then rerun the test. A persistent failure is useful as an issue report if it includes only the credential-safe launcher milestones.

## Item Assistant cannot find the game on another library/SD card

Point the detection helper at the actual game directory:

```bash
GRIM_DAWN_DIR='/run/media/deck/CARD/steamapps/common/Grim Dawn' \
./scripts/link-steam-detection.sh
```

If Steam itself is non-standard, also set `STEAM_ROOT`.

## Backups and prefix resets

Recreating or deleting compatdata `219990` removes Item Assistant, WebView2, .NET, its local database, and the detection links. Back up Item Assistant's data directory before any prefix reset:

```text
~/.local/share/Steam/steamapps/compatdata/219990/pfx/drive_c/users/steamuser/AppData/Local/EvilSoft/IAGD
```

Online sync is valuable but should not be treated as the only backup.
