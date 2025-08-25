{
  description = "gridbugs.org dev environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustPlatform = pkgs.makeRustPlatform {
          rustc = pkgs.rust-bin.stable.latest.default;
          cargo = pkgs.rust-bin.stable.latest.default;
        };
        caw_midi_udp_widgets_app = rustPlatform.buildRustPackage {
          pname = "caw_midi_udp_widgets_app";
          version = "0.3.0";

          src = pkgs.fetchCrate {
            pname = "caw_midi_udp_widgets_app";
            version = "0.3.0";
            hash = "sha256-gEpcx0DVbtD2Na9QzO0jpb5312hLWJMBP67RKvDvJNA=";
          };

          useFetchCargoVendor = true;
          cargoHash = "sha256-oON6k3qyVvrYUTaShdzpxIfG1RLx8vbYw7XFS7J1oyM=";

          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = with pkgs; [ SDL2 SDL2_ttf ];
          doCheck = false;
        };
        caw_viz_udp_app = rustPlatform.buildRustPackage {
          pname = "caw_viz_udp_app";
          version = "0.2.0";

          src = pkgs.fetchCrate {
            pname = "caw_viz_udp_app";
            version = "0.2.0";
            hash = "sha256-B+upQYdRjn0jEJS1/0ENoRCQQmKrrdH+4W46aRE2L4M=";
          };

          useFetchCargoVendor = true;
          cargoHash = "sha256-Ck6zYqAsOXWqsRGnDfcUGzGcIfUuXzw9k0+3hFpOdWI=";

          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = with pkgs; [ SDL2 ];
          doCheck = false;
        };
      in with pkgs; {
        devShell = mkShell rec {
          buildInputs = [
            caw_midi_udp_widgets_app
            #caw_viz_udp_app
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analysis" ];
            })
            evcxr
            python3Packages.jupyterlab
            python3Packages.ipython
            python3Packages.jupyter-lsp
            python3Packages.python-lsp-server

          ] ++ (if pkgs.stdenv.isLinux then [
            pkg-config
            udev
            alsa-lib
          ] else
            [ ]);

          shellHook = ''
            JUPYTER_DIR=$PWD/.jupyter
            mkdir -p $JUPYTER_DIR/app
            ${pkgs.evcxr}/bin/evcxr_jupyter --install

            export JUPYTER_PATH=$JUPYTER_DIR
          '';

          # Allows rust-analyzer to find the rust source
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

          # Without this graphical frontends can't find the GPU adapters
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildInputs}";

        };
      });
}
