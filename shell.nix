{
  pkgs ? import <nixpkgs> { },
}:

let
  libs = with pkgs; [
    alsa-lib
    libGL
    libx11
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    raylib
    sdl3
    sdl3-image
    systemd
    wayland
  ];
in
pkgs.mkShell {
  buildInputs =
    with pkgs;
    [
      odin
    ]
    ++ libs;

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (libs)}:$LD_LIBRARY_PATH"
  '';
}
