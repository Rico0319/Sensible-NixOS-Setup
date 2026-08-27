# home/ — home-manager config for ricoz.
#
# The declarative equivalent of sensible-fedora-setup's bootstrap.sh:
# the same daily-driver shell environment, minus the imperative steps.
# No Oh My Zsh installer, no git clones, no Homebrew — just this file.
{ config, pkgs, lib, ... }:

let
  # Oh My Zsh custom directory (plugins + theme) in the layout omz expects.
  # home-manager 26.05 removed `oh-my-zsh.customPkgs`, so we build the
  # custom dir ourselves — which also lets p10k be a real omz theme again,
  # exactly like the Fedora setup.
  zshCustom = pkgs.runCommand "zsh-custom" {} ''
    mkdir -p $out/plugins $out/themes

    # --- plugins ---------------------------------------------------------
    # zsh-autosuggestions ships an omz-layout dir already:
    ln -s ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions \
      $out/plugins/zsh-autosuggestions

    # zsh-syntax-highlighting does not; a wrapper gives it the omz layout:
    mkdir -p $out/plugins/zsh-syntax-highlighting
    cat > $out/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh <<'EOF'
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    EOF

    # --- theme -----------------------------------------------------------
    # p10k's package is already laid out as an omz theme:
    ln -s ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k $out/themes/powerlevel10k
  '';
in
{
  home.username = "ricoz";
  home.homeDirectory = "/home/ricoz";
  home.stateVersion = "26.05";

  # ~/.p10k.zsh — verbatim from the Fedora repo (files/p10k.zsh).
  home.file.".p10k.zsh".source = ../files/p10k.zsh;

  # ~/.local/bin on PATH (uv tool installs land there).
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.packages = with pkgs; [
    # The bootstrap.sh package list. Homebrew is gone — Nix replaces it.
    uv # Python tooling (uv tool install still works on top)
    tealdeer # tldr, without needing `uv tool install`
    gcc gnumake # @development-tools equivalent
  ];

  programs.git.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true; # $EDITOR / $VISUAL
  };

  programs.eza.enable = true;

  # Yazi, with the `y` cd-on-quit wrapper function (same as the Fedora zshrc).
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # zoxide (cd replacement) and fzf (keybindings + fuzzy completion).
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    shellAliases = {
      ls = "eza -lh --icons --git --group-directories-first";
      la = "eza -alh --icons --git --group-directories-first";
    };

    oh-my-zsh = {
      enable = true;
      # zsh-syntax-highlighting must stay LAST in this list (official
      # recommendation). The two non-bundled plugins come from the custom
      # dir built above (zshCustom).
      plugins = [ "git" "zsh-autosuggestions" "zsh-syntax-highlighting" ];
      custom = "${zshCustom}";
      theme = "powerlevel10k/powerlevel10k";
    };

    initContent = lib.mkMerge [
      # p10k instant prompt — must stay near the top of the generated
      # ~/.zshrc (mkBefore puts it before everything else, including OMz).
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Plain initContent lands after everything (OMz, zoxide, fzf, aliases)
      # — same position these lines hold in the Fedora zshrc.
      ''
        # --- Keybindings --------------------------------------------------------
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word

        # --- Helpers --------------------------------------------------------------
        function resource () {
          source ~/.zshrc
        }

        # --- Powerlevel10k --------------------------------------------------------
        # The theme is loaded by OMz (custom/themes/powerlevel10k); it sources
        # ~/.p10k.zsh itself, this is just belt-and-suspenders.
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      ''
    ];
  };
}
