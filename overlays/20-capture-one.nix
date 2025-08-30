self: super: with super; {
  capture-one = stdenvNoCC.mkDerivation rec {
    pname = "capture-one";
    version = "16.6.5.17";

    src = fetchurl {
      url = "https://downloads.captureone.pro/d/mac/39c0c6f987ddd1d187d6fb3cb3680b01673344cc/CaptureOne.Mac.16.6.5.17.dmg";
      sha256 = "sha256-PF1Y0GLk4qMqyEXnKFIWTRCCp/1TsGkjAM8adChGYv4=";
    };

    nativeBuildInputs = [
      undmg
      p7zip
    ];

    # Only unpack and install; never write to /Applications during build
    phases = [
      "unpackPhase"
      "installPhase"
    ];

    unpackPhase = ''
      # Ensure Unicode-capable locale so bsdtar/undmg can create UTF-8 paths
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export LC_CTYPE=en_US.UTF-8
      # Try undmg first; fall back to 7z extraction if it errors on filenames
      undmg "$src" || 7z x -y "$src"
    '';

    installPhase = ''
      # Find the app bundle inside the extracted dmg contents
      APP_NAME=$(find . -type d -name 'Capture One*.app' | head -n 1)
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
