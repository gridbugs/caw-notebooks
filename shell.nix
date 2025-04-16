{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
} }:

pkgs.mkShell rec {
  packages = with pkgs; [
    (rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" "rust-analysis" ];
      targets = [ "wasm32-unknown-unknown" ];
    })
    evcxr
    rust-analyzer
    python3Packages.jupyterlab
    python3Packages.ipython
    python3Packages.jupyter-lsp
    python3Packages.python-lsp-server
    pkg-config
    udev
    alsa-lib
  ];

  shellHook = ''
    JUPYTER_DIR=$PWD/.jupyter
    mkdir -p $JUPYTER_DIR/app
    ${pkgs.evcxr}/bin/evcxr_jupyter --install

    export JUPYTER_PATH=$JUPYTER_DIR
  '';

  # Allows rust-analyzer to find the rust source
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

  LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath packages}";
}
