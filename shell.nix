{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    pkg-config
    odin

    alsa-lib
    libGL
    libGLU
    raylib
    systemd
    wayland
    libx11
  ];
}
