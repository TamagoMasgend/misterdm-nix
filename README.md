# misterdm-nix

Nix packaging for [Mister Download Manager](https://misterdownloadmanager.com)
(`misterdownloadmanager`), built from the upstream
[`v0.5.2`](https://github.com/anefzaoui/misterdownloadmanager/tree/v0.5.2)
release tag (commit
[`605a0c7`](https://github.com/anefzaoui/misterdownloadmanager/commit/605a0c74e50361afe77bf1721d7172636bd5c57e)).
The version comes from the workspace `Cargo.toml` at that tag.

This is an unofficial packaging repository, not affiliated with the upstream
author.

The upstream repository has no `flake.nix` or other Nix expressions. It is a
Rust workspace (egui); this flake builds the four programs its Linux installer
ships (`tools/installer/build-linux.sh`):

| Program | Purpose |
| --- | --- |
| `misterdownloadmanager` (default) | the app |
| `misterdownloadmanager-cli` | the command line (downloads, videos, torrents, automation) |
| `misterdownloadmanager-nmhost` | browser native-messaging helper, started by the app and browsers |
| `misterdownloadmanager-mcp` | MCP server for AI assistants |

## Usage

Run without installing:

```sh
nix run github:TamagoMasgend/misterdm-nix
```

Use it as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    misterdm-nix.url = "github:TamagoMasgend/misterdm-nix";
  };

  outputs = { nixpkgs, misterdm-nix, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.overlays = [ misterdm-nix.overlays.default ];
          environment.systemPackages = [ pkgs.misterdownloadmanager ];
        })
      ];
    };
  };
}
```

Or take the package directly from the flake:

```nix
environment.systemPackages = [
  misterdm-nix.packages.${pkgs.stdenv.hostPlatform.system}.misterdownloadmanager
];
```

There is no NixOS or Home Manager module. Launch it from the desktop entry or
the terminal.

## What the packaging changes

- **No in-place update.** The install detection in
  `crates/tools/src/update.rs` is patched so a `/nix/store` path reports
  `Install::System` ("Another package manager"). Upstream returns no release
  assets for that kind (`Install::assets()` is empty), so no in-place update is
  offered; the update window says *"You have version …, from your system's
  package manager: update it there."* and shows no Update now button.
  The automatic new-version check remains as upstream ships it (enabled by
  default).
- **The autostart entry names the wrapper.** "Start with the session" writes an
  XDG autostart entry from `unix.rs::program()`; it now prefers `MDM_PROGRAM`,
  which the wrapper sets, so the session start gets the same environment.
- **Runtime libraries and tools.** The wrapper pins the tools below in `PATH`;
  the windowing and GL libraries are added to the program's `RUNPATH`, because
  winit and glutin load X11 or Wayland plus OpenGL/EGL at run time. wgpu loads
  Vulkan only when that renderer is selected (View → Draw with → Vulkan).
- **GPLv3 §5(a) notices and licensing.** Both source patches inject a dated
  `Modified by misterdm-nix (2026-11-10)` comment into the changed Rust file.
  The packaging and patches are GPL-3.0-or-later; see [`LICENSE`](LICENSE) for
  the GPLv3 text and [`NOTICE`](NOTICE) for the packaging notice.

## Runtime dependencies

The wrapper provides these; each is used by name or through GSettings in the
pinned source:

- `fontconfig` (`fc-match`): the interface font and per-character/script
  fallbacks.
- `glib` (`gsettings`, `gio`): the desktop's icon theme and colour scheme;
  moving deleted files to the Trash.
- `gsettings-desktop-schemas` (added to `XDG_DATA_DIRS`): the
  `org.gnome.desktop.interface` schemas read through `gsettings`.
- `xdg-utils` (`xdg-open`, `xdg-mime`): opening files and folders, and
  registering the desktop entry as the magnet/.torrent handler when that option
  is enabled.
- `systemd` (`systemctl`): the queue's "Turn off computer when done" action
  (`systemctl poweroff`, `hibernate` or `suspend`).
- `ffmpeg`: joining the video and sound most sites keep apart for the higher
  video qualities, and making MP3/Opus/FLAC.
- `pulseaudio` (`paplay`) and `alsa-utils` (`aplay`): download and queue sounds
  (`play_sound` tries `paplay`, then `aplay`).

TLS verification is left to `rustls-platform-verifier` (through rustls/reqwest),
so the platform's CA configuration is authoritative; this package pins no
certificate bundle. A real HTTPS download through the CLI was used to verify
this (see Verification).

The executable does not link the windowing libraries; winit and glutin load
X11 or Wayland plus OpenGL/EGL at run time. File dialogs use rfd's default XDG
desktop portal backend, so a desktop portal service is needed for them (on
NixOS: `xdg.portal`).

Video downloads use `yt-dlp` and `ffmpeg`. MDM can install its own signed
`yt-dlp` and `gallery-dl` into its data folder; a program chosen in Helpers →
Use another program takes priority, then MDM's own copy, then one found on
`PATH` (`docs/video.md` at the tag). On Linux MDM does not install ffmpeg
itself — its CLI offers `install-ffmpeg` for Windows only ("elsewhere the
system's") — so this package supplies `ffmpeg` in the wrapper's `PATH`.
`yt-dlp` and `gallery-dl` are deliberately not pinned here.

Browser integration is set up by the app itself at each start: it registers
`misterdownloadmanager-nmhost` for the browsers it finds. The app opens the
Chrome Web Store or addons.mozilla.org to add the extension.

## Verification

Exercised while packaging this flake:

- `nix build .#default` and `nix flake check`
- `misterdownloadmanager-cli --version` → `mdm-cli 0.5.2`
- a real HTTPS download through `misterdownloadmanager-cli --json get`
- a headless Xvfb launch (Mesa llvmpipe) that created the main window titled
  "Mister Download Manager 0.5.2" and the language chooser
- headless server mode (`--headless`), which printed its remote-control address
  and stopped cleanly on SIGTERM

Not exercised:

- installing the browser extension from the store
- completing a file-dialog interaction through the desktop portal
- an actual video download with `yt-dlp`/`ffmpeg`
- torrents

## Platforms

`x86_64-linux` only, matching upstream's Linux release. Upstream also builds
macOS and Windows; this packaging does not.

## Updating

Change `version` and `rev` (or tag) in
[`pkgs/misterdownloadmanager.nix`](pkgs/misterdownloadmanager.nix), refresh the
`src` hash and `pkgs/Cargo.lock`, and update the `outputHashes` if upstream's
`[patch.crates-io]` revisions change. `nix build` reports a mismatched hash or
a missing `outputHashes` entry with the value it expected.

## License

[`LICENSE`](LICENSE) is the GPLv3 text, byte-identical to the upstream
`LICENSE` at the pinned tag. [`NOTICE`](NOTICE) holds the packaging copyright
and GPL-3.0-or-later notice for the Nix packaging and patches.

Mister Download Manager itself is GPL-3.0-or-later, copyright its upstream
authors. It is built from tag
[`v0.5.2`](https://github.com/anefzaoui/misterdownloadmanager/tree/v0.5.2)
(commit
[`605a0c7`](https://github.com/anefzaoui/misterdownloadmanager/commit/605a0c74e50361afe77bf1721d7172636bd5c57e)).
The two patches are applied by `postPatch` in
[`pkgs/misterdownloadmanager.nix`](pkgs/misterdownloadmanager.nix), with the
dated modification notices described above. Upstream's `LICENSE` and
`ATTRIBUTION.md` are installed under `share/doc/misterdownloadmanager`.

This is an unofficial packaging repository, not affiliated with the upstream
author.
