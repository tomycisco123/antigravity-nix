{ lib
, stdenv
, fetchurl
, buildFHSEnv
, makeDesktopItem
, copyDesktopItems
, writeShellScript
, alsa-lib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, cups
, dbus
, expat
, glib
, google-chrome
, gtk3
, libdrm
, libgbm
, libnotify
, libsecret
, libuuid
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemd
, xorg
, zlib
}:

let
  pname = "google-antigravity";
  version = "1.11.2-6251250307170304";

  src = fetchurl {
    url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}/linux-x64/Antigravity.tar.gz";
    sha256 = "sha256-0bERWudsJ1w3bqZg4eTS3CDrPnLWogawllBblEpfZLc=";
  };

  # Extract and prepare the antigravity binary
  antigravity-unwrapped = stdenv.mkDerivation {
    inherit pname version src;

    dontBuild = true;
    dontConfigure = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/antigravity
      cp -r ./* $out/lib/antigravity/

      runHook postInstall
    '';

    meta = with lib; {
      description = "Google Antigravity - Next-generation agentic IDE";
      homepage = "https://antigravity.google";
      license = licenses.unfree;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };

  # FHS environment for running Antigravity
  fhs = buildFHSEnv {
    name = "antigravity-fhs";

    targetPkgs = pkgs: (with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      google-chrome
      gtk3
      libdrm
      libgbm
      libglvnd
      libnotify
      libsecret
      libuuid
      libxkbcommon
      mesa
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      systemd
      vulkan-loader
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence
      zlib
    ]);

    runScript = writeShellScript "antigravity-wrapper" ''
      # Set Chrome paths for browser automation support
      export CHROME_BIN=${google-chrome}/bin/google-chrome-stable
      export CHROME_PATH=${google-chrome}/bin/google-chrome-stable

      exec ${antigravity-unwrapped}/lib/antigravity/antigravity "$@"
    '';

    meta = antigravity-unwrapped.meta;
  };

  desktopItem = makeDesktopItem {
    name = "antigravity";
    desktopName = "Google Antigravity";
    comment = "Next-generation agentic IDE";
    exec = "antigravity %U";
    icon = "antigravity";
    categories = [ "Development" "IDE" ];
    startupNotify = true;
    startupWMClass = "Antigravity";
    mimeTypes = [
      "x-scheme-handler/antigravity"
      "text/plain"
    ];
  };

in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ copyDesktopItems ];

  desktopItems = [ desktopItem ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${fhs}/bin/antigravity-fhs $out/bin/antigravity

    # Install icon if available
    if [ -f ${antigravity-unwrapped}/lib/antigravity/resources/app/icon.png ]; then
      mkdir -p $out/share/pixmaps
      cp ${antigravity-unwrapped}/lib/antigravity/resources/app/icon.png $out/share/pixmaps/antigravity.png
    fi

    runHook postInstall
  '';

  meta = antigravity-unwrapped.meta;
}
