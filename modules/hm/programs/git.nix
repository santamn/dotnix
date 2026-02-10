{...}: {
  programs.delta = {
    enable = true;
    enableGitIntegration = true; # default is false in newer versions
  };
}
