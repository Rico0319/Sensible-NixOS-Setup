# modules/base.nix — shared base system for every host.
#
# The NixOS counterpart of sensible-fedora-setup's imperative system steps:
# packages, login shell, and SSH — but rollback-able and reproducible.
{ config, pkgs, lib, ... }:

{
  # --- Nix itself -------------------------------------------------------------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;

  # Keep the store from growing forever. Generations older than 30 days are
  # garbage-collected weekly — plenty of rollback runway, bounded disk usage.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # --- Users ---------------------------------------------------------------------
  users.users.ricoz = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;

    # Only so a truly headless first login is possible over SSH.
    # Change immediately, then add your key below and turn off password auth.
    initialPassword = "changeme";

    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... rico@..." ];
  };

  # --- SSH -------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      # TODO: flip to false once authorizedKeys.keys above is filled in.
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # --- Shell ------------------------------------------------------------------------
  # System-level zsh (registers it as a valid login shell); the actual
  # configuration — OMz, p10k, plugins, aliases — lives in home/.
  programs.zsh.enable = true;

  # --- Base packages -------------------------------------------------------------------
  # Minimal on purpose — user-level tooling comes from home-manager (home/).
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];
}
