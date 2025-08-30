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
      undmg "$src"
    '';

    installPhase = ''
      APP_NAME="Capture One.app"
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
