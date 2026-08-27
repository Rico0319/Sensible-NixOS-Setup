# modules/minecraft.nix — the Fabric dedicated server ("World 1", MC 26.2).
#
# NixOS equivalent of C:\Users\ricoz\mc-server\start.bat:
#     java -Xmx4G -jar fabric-server-launch.jar nogui
#
# The launcher jar is pinned by hash and matches the Windows copy
# byte-for-byte (verified 2026-08-27). World/mods/config/server.properties
# are stateful in /var/lib/minecraft — migrate them from the Windows
# directory once (see README, "Minecraft server").
{ config, pkgs, lib, ... }:

let
  # Fabric server launcher — MC 26.2, Loader 0.19.3, installer 1.1.2.
  fabricServerLauncher = pkgs.fetchurl {
    url = "https://meta.fabricmc.net/v2/versions/loader/26.2/0.19.3/1.1.2/server/jar";
    sha256 = "301f83aac36b23f2bc64cc58560edf98533cfaa30e53af002ba950c75f4100b4";
  };
in
{
  users.groups.minecraft = { };

  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
    home = "/var/lib/minecraft";
    createHome = true;
  };

  systemd.services.minecraft = {
    description = "Minecraft Fabric dedicated server (World 1 — MC 26.2)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      User = "minecraft";
      Group = "minecraft";
      WorkingDirectory = "/var/lib/minecraft";
      # Same as start.bat: java -Xmx4G -jar fabric-server-launch.jar nogui
      # (Prism's Java 21 "epsilon" runtime → pkgs.jdk21).
      ExecStart = "${pkgs.jdk21}/bin/java -Xmx4G -jar ${fabricServerLauncher} nogui";
      Restart = "on-failure";
      # Give the server time to save the world on stop:
      TimeoutStopSec = 120;
      # Light hardening: writes confined to the data dir.
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/minecraft" ];
      ProtectHome = true;
    };
  };

  # Minecraft (Java edition) uses TCP only. Friends can also join over
  # Tailscale — no port forwarding needed (see README).
  networking.firewall.allowedTCPPorts = [ 25565 ];
}
