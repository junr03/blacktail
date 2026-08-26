{
  username = "junr03";

  git = {
    name = "Jose Ulises Nino Rivera";
    email = "junr03@users.noreply.github.com";
    signingKey = "git-signature";
    signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };

  homeManager.backupFileExtension = "before-nix";

  ssh = {
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
