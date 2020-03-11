{ config, pkgs, lib, ... }:
let 
  # From https://github.com/jwiegley/nix-config/blob/master/overlays/30-apps.nix
  installApplication = 
    { name, appname ? name, version, src, description, homepage, 
      postInstall ? "", sourceRoot ? ".", ... }:
    with pkgs; stdenv.mkDerivation {
      name = "${name}-${version}";
      version = "${version}";
      src = src;
      buildInputs = [ undmg unzip ];
      sourceRoot = sourceRoot;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        mkdir -p "$out/Applications/${appname}.app"
        cp -pR * "$out/Applications/${appname}.app"
      '' + postInstall;
      meta = with stdenv.lib; {
        description = description;
        homepage = homepage;
        maintainers = with maintainers; [ kaali ];
        platforms = platforms.darwin;
      };
    };
  Hammerspoon = installApplication rec {
    name = "Hammerspoon";
    version = "0.9.78";
    sourceRoot = "Hammerspoon.app";
    src = pkgs.fetchurl {
      url = "https://github.com/Hammerspoon/hammerspoon/releases/download/0.9.78/Hammerspoon-0.9.78.zip";
      sha256 = "1zz5sbf2cc7qc90c8f56ksq87wx70akjy5nia0jsfhzvqmw8lsm0";
    };
    description = "Staggeringly powerful macOS desktop automation with Lua";
    homepage = https://www.hammerspoon.org;
  };
  emacsHEAD = with pkgs; stdenv.lib.overrideDerivation
    (pkgs.emacs26.override { srcRepo = true; }) (attrs: rec {
      name = "emacs-${version}${versionModifier}";
      version = "27.0";
      versionModifier = ".50";
      src = ~/dev/other/emacs;

      doCheck = false;

      buildInputs = attrs.buildInputs ++
        [ libpng libjpeg libungif libtiff librsvg
          jansson freetype harfbuzz.dev git];

      CFLAGS = "-O3 " + attrs.CFLAGS;

      preConfigure = ''
        sed -i -e 's/headerpad_extra=1000/headerpad_extra=2000/' configure.ac
        autoreconf
      '';

      patches = [
        ./patches/emacs/clean-env.patch
        ./nixpkgs/pkgs/applications/editors/emacs/tramp-detect-wrapped-gvfsd.patch
      ];
    });
  emacsPackages = pkgs.emacsPackagesNgGen emacsHEAD;
  emacsWithPackages = emacsPackages.emacsWithPackages (epkgs: [ epkgs.emacs-libvterm ]);
in {
  environment.systemPackages = with pkgs; [
    # editors
    emacsWithPackages
    vim

    # nix
    # nix-prefetch-scripts

    # utils
    ag
    ripgrep
    direnv
    fzf
    gitAndTools.gitFull
    coreutils
    fd
    httpie
    # (sox.override { enableLibsndfile = true; })
    entr
    ispell
    pandoc
    jq
    protobuf
    Hammerspoon
    postgresql # here for just psql

    # nodejs
    nodejs_latest
    pkgs.nodePackages.typescript-language-server
    pkgs.nodePackages.typescript
    pkgs.nodePackages.eslint
    pkgs.nodePackages.prettier

    # python
    pipenv
    python3
  ];

  environment.variables.EDITOR = "vim";

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
  programs.zsh.enable = true;
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
