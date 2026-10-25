# Windows development checkpoint

Paused at the maintainer's request to continue on a Windows computer. This branch is `codex/windows-1.14`. The released Mac `v1.14` is unchanged. A Windows installer has **not** been built or published yet.

## Requested scope

Extend T7moris/GPT-Niang's existing Windows WPF version, preserving its music, gallery, quote, audio, window-following and completion features. Port the Mac improvements: full short-tap feedback and speed/immediate mode, three independently configurable Easter eggs and repeat counts, fresh exact-zero eligibility, low-quota portrait/quote, main-window preference, bottom alignment, tray quota and character icon. Bundle Node and deliver an actual Windows x64 setup EXE, with upstream/media/icon credits and the existing project-use conditions.

## Current state

- Package/plugin development version: `1.14.1`.
- `runtime/windows-port.ps1`, `widget-motion.cs` and `widget-tray.cs` implement the first feature pass. The original GIF files and their timing are retained.
- Added `tests/windows-port.test.ps1`; existing `test.yml` can be dispatched on this branch to test on Windows. macOS job is skipped for this port workflow.
- First CI run `40167435195` failed because the new parser used Windows PowerShell's default file encoding. The parser now explicitly reads UTF-8 like the actual application loader. The second run `40167543486` also failed and still needs diagnosis.
- Additional installer work is saved in `windows/`: launcher, Inno Setup script, preflight/registration helpers and user instructions. The build script and installer smoke tests still need to be implemented.
- Installer-related changes add bundled-Node preference, an explicit login-startup option and suppression of upstream auto-updating for this custom build. These changes are not yet validated.

## Next steps on Windows

1. Inspect the second CI failure and finish the native feature tests; run the existing Windows regression tests without dropping existing functionality.
2. Build with the Windows runner's Inno Setup 6.7.1 (or a compatible local installation), .NET Framework C# compiler and a SHA-256-verified official Node.js v24.22.1 Windows x64 distribution.
3. Add a real silent install/start/upgrade/uninstall smoke test using an isolated fake Codex fixture, plus WPF rendering checks. Ensure optional startup does not create a logon shortcut or trigger when unchecked.
4. Verify package contents, original animation bytes/timing, notices, personal-data exclusion and installer checksums. No real account or chat data belongs in fixtures or artifacts.
5. Deliver the EXE and its checksum. A new Windows release has not been authorized for automatic publication; leave any new release as a reviewable draft unless the maintainer explicitly asks to publish it.

Do not rename or redeploy the installed Mac app, rewrite the released `v1.14` tag, overwrite its Mac download, remove original Windows functionality, redraw/interpolate the current original GIFs, or expand third-party permissions beyond the recorded project use.
