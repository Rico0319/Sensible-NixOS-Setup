# hosts/server — the 24/7 home server.
#
# Machine-specific config only; anything shared with future hosts belongs in
# modules/base.nix, and user-level tooling in home/.
{
  imports = [ ./hardware-configuration.nix ../../modules/minecraft.nix ];

  networking.hostName = "server";

  # UEFI boot with systemd-boot. Keep 10 generations in the boot menu so a
  # bad update is always one reboot away from being undone.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Adjust if the box lives elsewhere (e.g. "Asia/Shanghai").
  time.timeZone = "America/New_York";

  system.stateVersion = "26.05";

  # Default firewall posture: closed. Tailscale traffic is trusted.
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  # Remote access without opening any inbound ports. Run `sudo tailscale up`
  # once after first boot to authenticate.
  services.tailscale.enable = true;

  # Web admin panel (same tool Fedora ships on Fedora Server).
  # Browse to http://server:9090 and log in with your system credentials.
  # Works over Tailscale too (trusted interface). Note: the "Software
  # Updates" page is Fedora/dnf-specific; on NixOS updates happen via
  # `nixos-rebuild switch --flake .#server` instead. Services, logs,
  # terminal, storage, and networking pages all work.
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
  };
}
