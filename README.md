# Grim Dawn Item Assistant on Steam Deck

This project packages a tested way to run [Grim Dawn Item Assistant](https://grimdawn.evilsoft.net/) with the Steam edition of Grim Dawn on Steam Deck and SteamOS.

The key is a small, Grim-Dawn-only Steam compatibility tool. When you launch the official **Grim Dawn** library entry, it starts Item Assistant first, waits for its injection loop to initialize, and then launches the real game in the same Proton container. No separate Gaming Mode shortcut is needed.

## What works

- Item Assistant starts before Grim Dawn.
- Grim Dawn still launches through Steam App ID `219990` and renders normally.
- The hook DLL can reach the game because both processes share one Proton container.
- Items placed in the last shared-stash tab are imported automatically.
- Item Assistant online sync can share its inventory with a Windows PC.
- The same official Grim Dawn entry works in Desktop Mode and Gaming Mode.

The complete workflow was tested end to end on a Steam Deck on 19 August 2026. Sixteen test items were imported successfully, and the synchronized Item Assistant inventory count increased by 16.

## One-click Steam Deck installer

For the usual no-typing Steam Deck experience, download:

**[Install-Grim-Dawn-Item-Assistant.desktop](https://raw.githubusercontent.com/lbr88/grim-dawn-item-assistant-steam-deck/main/Install-Grim-Dawn-Item-Assistant.desktop)**

In Desktop Mode, move the downloaded file to the Desktop and double-click it. It downloads this repository and opens a guided KDE installer. The wizard can install Protontricks, lets you choose the three official Windows installers, opens Item Assistant for database/cloud configuration, and installs the combined Steam launcher.

Firefox may append `.download` to the filename. If it does, rename the file so it ends in `.desktop`. If KDE asks whether to execute the file, choose **Execute**; if necessary, open **Properties > Permissions** and enable **Is executable**.

The downloadable launcher follows the same `.desktop` installer pattern used by Steam Deck projects such as Decky. It downloads the installer script before running it and never requests `sudo` or an administrator password.

## Manual setup

Follow [docs/SETUP.md](docs/SETUP.md). The short version is:

1. Run Grim Dawn once with official Proton 10, then close it.
2. Install Item Assistant and its Windows dependencies into Grim Dawn's Proton prefix.
3. Link the Linux Steam config and Grim Dawn directory where Item Assistant expects Windows Steam.
4. Open Item Assistant by itself once to parse the game database and configure online sync.
5. Install the custom compatibility tool, restart Steam, and select **GD Item Assistant - Proton 10** for Grim Dawn.
6. From then on, launch only the official **Grim Dawn** entry.

The repository scripts detect the normal Steam Deck paths and also accept `STEAM_ROOT`, `PROTON_DIR`, and `GRIM_DAWN_DIR` overrides for non-default libraries.

## Everyday use

1. Launch **Grim Dawn** from Steam. Do not launch a separate Item Assistant shortcut.
2. Item Assistant appears first; Grim Dawn starts about 15 seconds later.
3. Enter a character and use the shared stash.
4. Put import items in the last shared-stash tab, close the stash, and walk away from the stash area.
5. Items transferred back from Item Assistant appear in the second-to-last shared-stash tab.
6. Exit Grim Dawn normally. The compatibility tool then closes Item Assistant so Steam can leave the Running state.

Gaming Mode exposes both windows in Steam's window switcher. The full Item Assistant interface is usable there, but its layout is much more comfortable in Desktop Mode or on Windows. The automatic infinite-stash import works without switching windows.

## Known-good versions

These are a record of the tested system, not a promise that they are the only compatible versions:

- Steam Deck / SteamOS
- Steam edition of Grim Dawn, App ID `219990`
- Proton 10.0
- Protontricks 1.14.1 Flatpak (configuration only)
- Grim Dawn Item Assistant 1.5.9700.13021
- .NET Desktop Runtime 10.0.11, Windows x64
- Microsoft Edge WebView2 Runtime 151.0.4129.93

Use Item Assistant's current upstream requirements when they change. The scripts locate the installed WebView2 version dynamically rather than hard-coding the version above.

## Important notes

- Item Assistant online sync is separate from Steam Cloud. Use the same Item Assistant account on both machines and let the initial download finish before importing items.
- Never publish the Item Assistant `cloudAuthToken`, account address, `settings.json`, `userdata.db`, Proton prefix, or Steam `config.vdf`.
- Back up your Grim Dawn saves and Item Assistant data before changing a Proton prefix.
- This repository does not redistribute Grim Dawn, Proton, Item Assistant, .NET, WebView2, or any other third-party binary.
- This is an unofficial community workaround and is not affiliated with Crate Entertainment, Valve, Microsoft, or the Item Assistant author.

For failure symptoms and recovery steps, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md). For the process/container explanation, see [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md).

## Upstream references

- [Grim Dawn Item Assistant](https://grimdawn.evilsoft.net/)
- [Item Assistant source](https://github.com/marius00/iagd)
- [Protontricks](https://github.com/Matoking/protontricks)
- [Community Linux/Proton guide](https://forums.crateentertainment.com/t/guide-grim-dawn-item-assistant-on-linux/150469)

## License

[MIT](LICENSE). The software and instructions are provided without warranty; see the license text for the full liability disclaimer.
