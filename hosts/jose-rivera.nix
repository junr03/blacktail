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
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFm5pc5GPaOK/kU9IWy7ihY8GztLSXCIhMjLNebz3krj blacktail-github";
    };
    electricpeak = {
      host = "electricpeak.net";
      identityFile = "electricpeak";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMJCupdhovwN0fRQlzbfGMj/v2dMq16o+OH4IQDsrdk blacktail-electricpeak";
      user = "junr03";
    };
  };
}
