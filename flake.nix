{
  description = "Nix packaging for Mister Download Manager (misterdownloadmanager)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system} system);

      overlay = final: _prev: {
        misterdownloadmanager = final.callPackage ./pkgs/misterdownloadmanager.nix { };
      };
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (
        pkgs: _: rec {
          misterdownloadmanager = pkgs.callPackage ./pkgs/misterdownloadmanager.nix { };
          default = misterdownloadmanager;
        }
      );

      checks = forAllSystems (
        pkgs: system:
        let
          inherit (self.packages.${system}) misterdownloadmanager;
        in
        {
          inherit misterdownloadmanager;

          # `misterdownloadmanager-cli` execs the app's program with `--cli`; clap there
          # prints the version, so this checks the installed layout and the launcher's exec.
          cli = pkgs.runCommand "misterdownloadmanager-cli-check" { } ''
            ${misterdownloadmanager}/bin/misterdownloadmanager-cli --version \
              | grep -F "${misterdownloadmanager.version}"
            touch $out
          '';
        }
      );

      formatter = forAllSystems (pkgs: _: pkgs.nixfmt-tree);

      apps = forAllSystems (
        _pkgs: system: {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/misterdownloadmanager";
            meta.description = "Open Mister Download Manager";
          };
        }
      );
    };
}
