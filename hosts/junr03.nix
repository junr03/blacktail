{
  username = "junr03";

  git = {
    name = "Jose Ulises Nino Rivera";
    email = "junr03@users.noreply.github.com";
  };

  homeManager.backupFileExtension = "before-nix";

  ssh = {
    github = {
      host = "github.com";
      identityFile = "github";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFepB8gnsQw2fqna5epnucL2/UBL+1pQoh26GlKH29ye recruiting@junr03.com";
    };
    electricpeak = {
      host = "electricpeak.net";
      identityFile = "electricpeak";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVuvU35QsaFextBWDvK/Bsz+2YGwpMO+J4dFZMukuj7 admin@electricpeak.net";
    };
  };
}
