self: super: with super; {
  capture-one =
    let
      version = "16.6.5.17";
    in
    fetchurl {
      url = "https://downloads.captureone.pro/d/mac/39c0c6f987ddd1d187d6fb3cb3680b01673344cc/CaptureOne.Mac.16.6.5.17.dmg";
      sha256 = "sha256-PF1Y0GLk4qMqyEXnKFIWTRCCp/1TsGkjAM8adChGYv4=";
      name = "CaptureOne-${version}.dmg";
    };
}
