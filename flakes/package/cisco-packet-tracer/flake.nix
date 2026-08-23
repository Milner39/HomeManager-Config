{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    systems = [ "x86_64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

    pname = "cisco-packet-tracer";
    version = "1.0.0";

    # Check file exists so this can fail gracefully
    CPT-deb = self + "/CiscoPacketTracer.deb";
    CPT-deb-present = builtins.pathExists CPT-deb;
  in {
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        appimageTools = pkgs.appimageTools;

        CPT-appimage = pkgs.stdenv.mkDerivation {
          pname = "${pname}-appimage";
          version = version;

          src = CPT-deb;

          nativeBuildInputs = with pkgs; [
            dpkg
          ];

          unpackPhase = ''
            echo "Unpacking .deb file"
            mkdir deb
            dpkg-deb -x "$src" deb
            echo "Unpacked .deb file"
          '';

          buildPhase = "true";

          installPhase = ''
            echo "Finding .AppImage file"
            appimage="$(find deb -name '*.AppImage' | head -n1)"
            if [ -z "$appimage" ]; then
              echo "ERROR: No AppImage found in deb"
              ls -R deb || true
              exit 1
            fi
            echo "Found .AppImage file: $appimage"

            mkdir -p $out
            cp "$appimage" "$out/cisco-packet-tracer.AppImage"
          '';
        };

        CPT = appimageTools.wrapType2 {
          pname = pname;
          version = version;

          src = "${CPT-appimage}/cisco-packet-tracer.AppImage";
          extraPkgs = pkgs: with pkgs; [
            libpng
            libxkbfile
          ];

          extraInstallCommands = ''
            # Add a desktop entry
            mkdir -p "$out/share/applications"
            cat > "$out/share/applications/cisco-packet-tracer.desktop" <<EOF
            [Desktop Entry]
            Type=Application
            Name=Cisco Packet Tracer
            GenericName=Network Simulator
            Comment=Network simulation tool
            Exec=${pkgs.util-linux}/bin/unshare --user --map-current-user --net $out/bin/cisco-packet-tracer
            Icon=cisco-packet-tracer
            Terminal=false
            Categories=Network;Education;
            EOF
          '';
        };


        CPT-stub = pkgs.writeShellScriptBin "cisco-packet-tracer" ''
          echo "Cisco Packet Tracer is not installed." >&2
          echo "The build could not find CiscoPacketTracer.deb, so a stub was built instead." >&2
          echo "See flakes/package/cisco-packet-tracer/README.md for how to add the installer." >&2
          exit 1
        '';
      in {
        "${pname}" = if CPT-deb-present
          then CPT
          else builtins.warn
            "cisco-packet-tracer: CiscoPacketTracer.deb not found - building a stub package instead. See flakes/package/cisco-packet-tracer/README.md."
            CPT-stub;
      }
    );
  };
}
