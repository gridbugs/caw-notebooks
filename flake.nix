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
        caw = rustPlatform.buildRustPackage {
          pname = "caw_midi_udp_widgets_app";
          version = "0.1.0";

          src = pkgs.fetchCrate {
            pname = "caw_midi_udp_widgets_app";
            version = "0.1.0";
            hash = "sha256-lnpy1qPy84y2swfp4WPDsVWx9a7tRP+iGHtuGL8p8mA=";
          };

          useFetchCargoVendor = true;
          cargoHash = "sha256-n3JYXs63Esrbm4CcsIkhETSip8SKIFmC8MwNB6OzLmg=";

          nativeBuildInputs = [ pkgs.pkg-config ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.CoreServices
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ];

          buildInputs = with pkgs;
            [ SDL2 SDL2_ttf ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.CoreServices
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ];

          doCheck = false;
        };
      in with pkgs; {
        devShell = mkShell rec {
          buildInputs = [
            caw
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
