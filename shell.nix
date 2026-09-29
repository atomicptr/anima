{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    alsa-lib
    libGL
    libx11
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    odin
    systemd
    wayland
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="${
      pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          wayland
          libx11
          libxcursor
          libxrandr
          libxi
          libxinerama
          libGL
          libxkbcommon
          alsa-lib
          systemd
        ]
      )
    }:$LD_LIBRARY_PATH"
  '';
}
