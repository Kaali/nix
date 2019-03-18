{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # editors
    emacsMacport
    vim

    # nix
    nix-prefetch-scripts

    # utils
    ripgrep
    direnv
    fzf
    gitAndTools.gitFull
    coreutils
    fd

    # nodejs
    nodejs-10_x
    pkgs.nodePackages.javascript-typescript-langserver

    # python
    (python36.withPackages(ps: with ps; [
      setuptools
      jedi
      rope
      isort
      yapf
      python-language-server
    ]))
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.activate-system.enable = true;
  nix.package = pkgs.nixUnstable;
  nix.nixPath = [
    "darwin-config=$HOME/dev/nix/darwin-configuration.nix"
    "darwin=$HOME/dev/nix/darwin"
    "nixpkgs=$HOME/dev/nix/nixpkgs"
    "$HOME/.nix-defexpr/channels"
    "$HOME/.nix-defexpr"
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;
  programs.bash.enableCompletion = true;
  # programs.zsh.enable = true;
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 3;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 8;
  nix.buildCores = 1;

  programs.nix-index.enable = true;
}
