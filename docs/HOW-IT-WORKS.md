# How the runtime workaround works

Item Assistant is not merely a viewer. It starts an injector that loads its hook DLL into the running Grim Dawn process so it can observe shared-stash changes.

On SteamOS, two facts conflict:

1. Item Assistant should initialize before Grim Dawn.
2. The injector and game need compatible process and Wine/Proton boundaries.

Starting Item Assistant separately with Flatpak Protontricks and then launching Grim Dawn creates separate Linux runtime containers. Item Assistant may see the process, but its injector cannot write into it. Starting Item Assistant separately inside the same prefix can also cause Steam's normal `waitforexitandrun` Proton verb to wait for the existing prefix process forever, so the game never starts.

The custom compatibility tool makes Steam launch one application session that contains both Windows programs:

```text
Steam App 219990
└── one Steam Linux Runtime / Proton container
    ├── IAGrim.exe
    └── Grim Dawn.exe
```

Its launch sequence is:

1. Steam invokes the custom tool for App ID `219990` using `waitforexitandrun`.
2. The wrapper starts `IAGrim.exe` with official Proton 10's `runinprefix` action.
3. It waits 15 seconds so the Item Assistant UI, WebView2, and injection loop can initialize.
4. It calls official Proton 10's `run` action with Steam's original Grim Dawn executable and arguments unchanged.
5. When the game exits, it asks Wine to close `IAGrim.exe`, preventing Steam from remaining in a false Running state.

All other Proton verbs are forwarded directly to official Proton 10. The installed tool symlinks to the existing Proton runtime, so it does not patch or redistribute Proton.

## Why the working directory and WebView2 override exist

Item Assistant looks for `ItemAssistantHook_x64.dll` relative to its working directory. Launching it from an arbitrary Linux directory caused it to look for the DLL in the wrong place. Both launchers therefore start from `C:\Program Files\IAGD`.

WebView2's files were installed in the prefix but were not discovered reliably through Wine's runtime registration. The scripts find the newest installed directory containing `msedgewebview2.exe` and set `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` to that directory.

## Scope

The compatibility tool is selected only for Grim Dawn. It does not change the global Proton configuration, patch game files, edit Item Assistant, or modify official Proton 10.
