{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  imagemagick,
  cmake,
  pkg-config,
  aws-lc,
  ffmpeg,
  alsa-utils,
  fontconfig,
  glib,
  gsettings-desktop-schemas,
  libglvnd,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxinerama,
  libxkbcommon,
  libxrandr,
  libxxf86vm,
  pulseaudio,
  systemd,
  vulkan-loader,
  wayland,
  xdg-utils,
  versionCheckHook,
}:

let
  # winit, glutin and wgpu load the windowing, GL/EGL and Vulkan libraries with dlopen.
  # The store has no ldconfig cache, so the loader learns about them from the program's
  # RUNPATH.
  dlopenLibs = [
    libglvnd
    libx11
    libxcb
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    libxxf86vm
    wayland
    vulkan-loader
  ];

  # Programs the app runs on Linux: fc-match (fonts), gsettings (icon theme and dark mode),
  # xdg-open/xdg-mime (opening and registering files), gio (Trash), systemctl (shut down,
  # suspend when downloads finish), ffmpeg (merging the video qualities a site splits and
  # making MP3/Opus/FLAC; on Linux the app installs yt-dlp itself but not ffmpeg), paplay/aplay
  # (Options → Sounds).
  runtimeTools = [
    fontconfig
    glib
    xdg-utils
    systemd
    ffmpeg
    pulseaudio
    alsa-utils
  ];
in
rustPlatform.buildRustPackage {
  pname = "misterdownloadmanager";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "anefzaoui";
    repo = "misterdownloadmanager";
    rev = "605a0c74e50361afe77bf1721d7172636bd5c57e";
    hash = "sha256-WRBG1npj6+//0YjWooMmw03ngVRkDx1WyhvwOL2+7sc=";
  };

  # The workspace's git dependencies (storytold/craft-libs, the egui and winit forks, and
  # anefzaoui/rqbit), keyed by package name-version as importCargoLock expects; all crates
  # from one repository share that repository's tree hash.
  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "craft-atomic-0.1.0" = "sha256-6Q6qpUD73D9aUntjL9g9ovJHXwsWzQZpxsvlGsxEZmI=";
      "craft-i18n-0.1.0" = "sha256-6Q6qpUD73D9aUntjL9g9ovJHXwsWzQZpxsvlGsxEZmI=";
      "ecolor-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "eframe-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "egui-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "egui-wgpu-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "egui-winit-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "egui_extras-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "egui_glow-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "emath-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "epaint-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "epaint_default_fonts-0.37.0" = "sha256-DJMKiXh4+gb9iWz7gzLzqvc2wphKlzGyftS/JeC/sW8=";
      "librqbit-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-bencode-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-buffers-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-clone-to-owned-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-core-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-dht-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-lsd-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-peer-protocol-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-sha1-wrapper-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-tracker-comms-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "librqbit-upnp-9.1.0" = "sha256-HG8QU12drTXWYCrTFhd/XbJLhpXR7Z7jf5wDzqzsH4k=";
      "winit-0.30.13" = "sha256-+67bk7cqhM5VHqROL3PeghmhKJvlPIxhU73ay45vaxw=";
    };
  };

  # The workspace also holds the lab server, benchmarks and examples; only the four programs
  # upstream ships (tools/installer/build-linux.sh) are built and installed.
  cargoBuildFlags = [
    "-p"
    "mdm-app"
    "-p"
    "mdm-nmhost"
    "-p"
    "mdm-cli"
    "-p"
    "mdm-mcp"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
    copyDesktopItems
    imagemagick
  ];

  # cargoSetupHook sets AWS_LC_SYS_USE_SYSTEM; rustls's aws-lc-rs then links this instead of
  # building its vendored copy.
  buildInputs = [ aws-lc ];

  postPatch = ''
    # A Nix store copy is updated by Nix, never by MDM's in-place updater (which would try to
    # replace a read-only store path). Install::System's assets() is empty.
    substituteInPlace crates/tools/src/update.rs \
      --replace-fail '    let Some(path) = exe.to_str() else {' \
        '    if exe.starts_with("/nix/store/") {
               return Install::System;
           }
           let Some(path) = exe.to_str() else {'

    # Start with the session through the wrapper, so the autostart entry gets the same PATH as
    # a launch from the desktop entry. The wrapper sets MDM_PROGRAM.
    substituteInPlace crates/app/src/unix.rs \
      --replace-fail '    std::env::var_os("APPIMAGE")
            .map(PathBuf::from)
            .or_else(|| std::env::current_exe().ok())' \
        '    std::env::var_os("MDM_PROGRAM")
            .map(PathBuf::from)
            .or_else(|| std::env::var_os("APPIMAGE").map(PathBuf::from))
            .or_else(|| std::env::current_exe().ok())'
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "misterdownloadmanager";
      desktopName = "Mister Download Manager";
      comment = "Download manager";
      exec = "misterdownloadmanager %U";
      icon = "misterdownloadmanager";
      categories = [
        "Network"
        "FileTransfer"
      ];
      mimeTypes = [
        "x-scheme-handler/magnet"
        "application/x-bittorrent"
      ];
    })
  ];

  postInstall = ''
    # Upstream's build-linux.sh resizes this 1254 px artwork for hicolor.
    install -Dm644 "art/Mister Download Manager.png" "$TMPDIR/mdm-icon.png"
    install -d $out/share/icons/hicolor/256x256/apps
    magick "$TMPDIR/mdm-icon.png" -resize 256x256 \
      $out/share/icons/hicolor/256x256/apps/misterdownloadmanager.png

    install -Dm644 LICENSE ATTRIBUTION.md -t $out/share/doc/misterdownloadmanager

    wrapProgram $out/bin/misterdownloadmanager \
      --set MDM_PROGRAM $out/bin/misterdownloadmanager \
      --suffix PATH : ${lib.makeBinPath runtimeTools} \
      --suffix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}
  '';

  # postFixup runs after fixupPhase pruned nothing (there is no DT_NEEDED for these). The
  # wrapper renamed the program; the loader reads the RUNPATH from the real binary.
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath dlopenLibs} $out/bin/.misterdownloadmanager-wrapped
  '';

  # Upstream's tests start a lab HTTP/FTP server and exercise the GUI's command line; they are
  # not part of a package build. The flake's checks run the installed programs instead.
  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/misterdownloadmanager-cli";

  meta = {
    description = "Download manager with torrents, video downloads and browser integration";
    homepage = "https://misterdownloadmanager.com";
    changelog = "https://github.com/anefzaoui/misterdownloadmanager/blob/v0.5.2/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "misterdownloadmanager";
    platforms = [ "x86_64-linux" ];
  };
}
