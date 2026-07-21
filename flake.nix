{
  description = "Nix flake for fly-in";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = nixpkgs.lib.systems.flakeExposed;
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forEachSystem (pkgs: {
        default =
          let
            x11Libs = with pkgs; [
              libX11
              libXrandr
              libXrender
              libXext
              libXcursor
              libXinerama
              libXi
              libXxf86vm
              libxcb
            ];
            glLibs = with pkgs; [
              libGL
            ];
            fontLibs = with pkgs; [
              freetype
              fontconfig
            ];
          in
          pkgs.mkShellNoCC {
            packages = [
              pkgs.python313
              pkgs.uv
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux (glLibs ++ x11Libs ++ fontLibs);
            env = {
              UV_PYTHON_DOWNLOADS = "never";
              UV_PYTHON = "${pkgs.python313}/bin/python3.13";
            }
            // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
              LD_LIBRARY_PATH =
                "/run/opengl-driver/lib:/run/opengl-driver-32/lib:"
                + pkgs.lib.makeLibraryPath ([ pkgs.stdenv.cc.cc.lib ] ++ glLibs ++ x11Libs ++ fontLibs);
            };
            shellHook = ''
              # Clean PATH to remove directories containing compilers/linkers (gcc, g++, ld, cc, clang, ar)
              # This prevents ctypes.util.find_library from performing slow compilation/linkage subprocess checks on NixOS,
              # dropping the startup time of pyglet/arcade from 9+ seconds to instant (0.25 seconds).
              NEW_PATH=""
              IFS=':' read -ra ADDR <<< "$PATH"
              for p in "''${ADDR[@]}"; do
                if [ -d "$p" ] && [ ! -f "$p/gcc" ] && [ ! -f "$p/g++" ] && [ ! -f "$p/ld" ] && [ ! -f "$p/cc" ] && [ ! -f "$p/clang" ] && [ ! -f "$p/ar" ]; then
                  if [ -z "$NEW_PATH" ]; then
                    NEW_PATH="$p"
                  else
                    NEW_PATH="$NEW_PATH:$p"
                  fi
                fi
              done
              export PATH="$NEW_PATH"
            '';
          };
      });
    };
}
