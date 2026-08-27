# hosts/server/hardware-configuration.nix — PLACEHOLDER.
#
# !!! Replace this file with the real one before `nixos-install`:
#
#     # on the installer, with the target mounted at /mnt:
#     nixos-generate-config --root /mnt
#     cp /mnt/etc/nixos/hardware-configuration.nix hosts/server/
#
# The example below (single disk, UEFI, ext4 root) only exists so the flake
# evaluates on any machine, e.g. for `nix flake check` from a laptop.
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos"; # adjust
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP"; # adjust
    fsType = "vfat";
  };

  # External media SSD — mount by UUID, never /dev/sdX, and use nofail so a
  # missing/unplugged SSD can't hang a headless boot.
  # fileSystems."/mnt/media" = {
  #   device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };
}
