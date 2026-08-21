{
  username = "jose.rivera";

  git = {
    name = "Jose Ulises Nino Rivera";
    email = "junr03@users.noreply.github.com";
  };

  homeManager.backupFileExtension = "before-nix";

  devbox = {
    repoPath = "github/cloud";
    awsProfile = "cloud_zipline_devs_prod";
    instanceId = "i-0407615d5d40bd7d1";
    region = "us-west-2";
  };

  ssh = {
    devbox = {
      host = "devbox";
      hostName = "devbox_jose_nino_rivera.int.flyzipline.com";
      identityFile = "devbox";
      user = "ubuntu";
    };
    github = {
      host = "github.com";
      identityFile = "github";
    };
    electricpeak = {
      host = "electricpeak.net";
      identityFile = "electricpeak";
      user = "junr03";
    };
  };
}
