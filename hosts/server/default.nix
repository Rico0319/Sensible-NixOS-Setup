# hosts/server — the 24/7 home server.
#
# Machine-specific config only; anything shared with future hosts belongs in
# modules/base.nix, and user-level tooling in home/.
{
  imports = [ ./hardware-configuration.nix ];

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
}
