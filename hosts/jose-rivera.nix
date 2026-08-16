{
  username = "jose.rivera";

  git = {
    name = "Jose Ulises Nino Rivera";
    email = "junr03@users.noreply.github.com";
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
