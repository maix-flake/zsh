{
  description = "My zsh flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    naersk.url = "github:nix-community/naersk";
    flake-utils.url = "github:numtide/flake-utils";

    starship = {
      url = "github:maix0/starship-flake";
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
      starship = naersk'.buildPackage {src = inputs.starship-flake;};
      starship_config = builtins.readFile ./starship_config.toml;
      zshrc_data = ''

        [ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv"
        [ -f "$HOME/.zvars"  ] && source "$HOME/.zvars"

        #export STARSHIP_CONFIG="${pkgs.writeTextFile "starship-config.toml" starship_config}"
        eval "$(${starship}/bin/starship init zsh)"
      '';
    in {
      packages = rec {
        default = zsh;
        zsh = pkgs.mkDerivation {
          name = "zsh";
          version = "0.0.0";
        };
      };

      app = rec {
        default = zsh;
        zsh = flake-utils.mkApp {
          name = "zsh";
          drv = self.packages.${system}.zsh;
        };
        install = flake-utils.mkApp {};
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
