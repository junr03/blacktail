self: super: with super; {
  capture-one = stdenvNoCC.mkDerivation rec {
    pname = "capture-one";
    version = "16.6.5.17";

    src = fetchurl {
      url = "https://downloads.captureone.pro/d/mac/39c0c6f987ddd1d187d6fb3cb3680b01673344cc/CaptureOne.Mac.16.6.5.17.dmg";
      sha256 = "sha256-PF1Y0GLk4qMqyEXnKFIWTRCCp/1TsGkjAM8adChGYv4=";
    };

    nativeBuildInputs = [ undmg ];

    # Only unpack and install; never write to /Applications during build
    phases = [
      "unpackPhase"
      "installPhase"
    ];

    unpackPhase = ''
      # Avoid macOS coreutils locale issues when extracting weird filenames
      export LANG=C
      export LC_ALL=C
      undmg "$src"
    '';

    installPhase = ''
      # Find the app bundle inside the extracted dmg contents
      APP_NAME=$(find . -maxdepth 1 -type d -name 'Capture One*.app' | head -n 1)
      if [ -z "$APP_NAME" ]; then
        echo "Failed to locate Capture One .app in DMG"
        ls -la
        exit 1
      fi
      mkdir -p "$out/Applications"
      cp -R "$APP_NAME" "$out/Applications/"
    '';

    meta = with lib; {
      description = "Capture One photo editing software";
      homepage = "https://www.captureone.com/";
      license = licenses.unfree;
      platforms = platforms.darwin;
    };
  };
}
