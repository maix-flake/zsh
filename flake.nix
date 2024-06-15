{
  description = "My zsh flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    naersk.url = "github:nix-community/naersk";
    flake-utils.url = "github:numtide/flake-utils";

    starship = {
      url = "github:maix0/starship";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      naersk' = pkgs.callPackage inputs.naersk {};
      starship = naersk'.buildPackage {
        src = inputs.starship;
        buildInputs = [pkgs.cmake];
      };
      starship_config = builtins.readFile ./starship-config.toml;
      zshrc_data = ''
        [ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv";
        [ -f "$HOME/.zvars"  ] && source "$HOME/.zvars";

        ZINIT_HOME="''${XDG_DATA_HOME:-''${HOME}/.local/share}/zinit/zinit.git"
        [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
        [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        source "''${ZINIT_HOME}/zinit.zsh"

        zinit light z-shell/F-Sy-H
        zinit light zsh-users/zsh-syntax-highlighting
        zinit light zsh-users/zsh-completions
        zinit light zsh-users/zsh-autosuggestions
        zinit light Aloxaf/fzf-tab
        zinit light nix-community/nix-zsh-completions

        zinit snippet OMZP::git
        zinit snippet OMZP::sudo

        autoload -Uz compinit && compinit

        SAVEHIST=$HISTSIZE
        HISTDUP=erase
        setopt appendhistory
        setopt sharehistory
        setopt hist_ignore_space
        setopt hist_ignore_all_dups
        setopt hist_save_no_dups
        setopt hist_ignore_dups
        setopt hist_find_no_dups

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


        export STARSHIP_CONFIG="${pkgs.writeTextFile {
          name = "starship-config.toml";
          text = starship_config;
        }}"
        eval "$(${starship}/bin/starship init zsh)"
        eval "$(direnv hook zsh)"
        eval "$(fzf --zsh)"
        eval "$(zoxide init --cmd cd zsh)"

        enable_transience || true

          ${pkgs.fortune}/bin/fortune \
        | ${pkgs.cowsay}/bin/cowsay   \
        | ${pkgs.dotacat}/bin/dotacat

        alias -- 'cat'='${pkgs.bat}/bin/bat -p'
        alias -- 'ls'='${pkgs.eza}/bin/eza --icons -a'
      '';
      zsh_config_file = pkgs.writeTextFile {
        name = ".zshrc";
        text = zshrc_data;
        destination = "/.zshrc";
      };
    in {
      packages = rec {
        inherit starship;
        default = zsh;
        zsh =
          pkgs.writeScriptBin "zsh"
          ''
            #!/bin/sh
            ZDOTDIR="${zsh_config_file}/" ${pkgs.zsh}/bin/zsh "$@"
          '';
      };

      apps = rec {
        default = zsh;
        zsh = flake-utils.lib.mkApp {
          name = "zsh";
          drv = self.packages.${system}.zsh;
        };
      };
      #   home.packages = [pkgs.nix-zsh-completions];
      #   programs = {
      #     nix-index = {
      #       enable = true;
      #       enableZshIntegration = true;
      #     };
      #     zsh = {
      #       enable = true;
      #       enableCompletion = true;
      #       oh-my-zsh = {
      #         enable = true;
      #         plugins = ["git" "wd" "rust"];
      #       };
      #       plugins = [
      #         {
      #           name = "F-Sy-H";
      #           file = "F-Sy-H.plugin.zsh";
      #           src = inputs.fast-syntax-highlighting;
      #         }
      #         {
      #           name = "zsh-nix-shell";
      #           file = "nix-shell.plugin.zsh";
      #           src = inputs.zsh-nix-shell;
      #         }
      #       ];
      #       initExtra = ''
      #         export PATH="$PATH:$HOME/bin"
      #         source ~/.p10k.zsh
      #         source ~/.powerlevel10k/powerlevel10k.zsh-theme
      #         if [ -f "$HOME/.zvars" ]; then
      #           source "$HOME/.zvars"
      #         fi
      #
      #         if [ -f "$HOME/.localrc.sh" ]; then
      #           source "$HOME/.localrc.sh"
      #         fi
      #
      #         export PATH="${config.home.homeDirectory}/bin:$PATH"
      #
      #         ${pkgs.fortune}/bin/fortune \
      #           | ${pkgs.cowsay}/bin/cowsay \
      #           | ${pkgs.dotacat}/bin/dotacat
      #       '';
      #       shellAliases = {
      #         cat = "${pkgs.bat}/bin/bat -p";
      #         ls = "${pkgs.exa}/bin/exa --icons -a";
      #         vim = "nvim";
      #       };
      #     };
      #   };
      #
      #   home.file = {
      #     ".zprofile".source = ./zprofile;
      #   };
      # };
    });
}
