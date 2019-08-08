{ config, pkgs, lib, ... }:
let
  emacsHEAD = with pkgs; stdenv.lib.overrideDerivation
    (pkgs.emacs26.override { srcRepo = true; }) (attrs: rec {
      name = "emacs-27.0";
      version = "27.0";
      versionModifier = "";

      doCheck = false;

      buildInputs = attrs.buildInputs ++ [jansson];

      CFLAGS = "";

      patches = [
        ./patches/emacs/clean-env.patch
        ./nixpkgs/pkgs/applications/editors/emacs/tramp-detect-wrapped-gvfsd.patch
      ];

      src = fetchgit {
        url = https://git.savannah.gnu.org/git/emacs.git;
        rev = "8f4faf7aa1a1b92dbd4d1512592da44e47777e4b";
        sha256 = "08y8z87y9f05nwjw5m3dg1ycpf54q64n63fv88b6m88m60k0x8q5";
      };
    });
in {
  environment.systemPackages = with pkgs; [
    # editors
    emacsHEAD
    vim

    # nix
    nix-prefetch-scripts

    # utils
    ag
    ripgrep
    direnv
    fzf
    gitAndTools.gitFull
    coreutils
    fd
    httpie
    (sox.override { enableLibsndfile = true; })
    entr
    ispell
    pandoc
    jq

    # nodejs
    nodejs_latest
    pkgs.nodePackages.javascript-typescript-langserver
    pkgs.nodePackages.eslint
    pkgs.nodePackages.prettier

    # python
    pipenv
    python3
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.activate-system.enable = true;
  nix.package = pkgs.nix;
  nix.nixPath = lib.mkForce [
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
  system.stateVersion = 4;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 1;
  nix.buildCores = 1;

  programs.nix-index.enable = true;
}
