# Sensible-NixOS-Setup

Declarative NixOS configuration — the NixOS counterpart to
[sensible-fedora-setup](https://github.com/Rico0319/sensible-fedora-setup).
Same daily-driver shell environment; here it's a flake instead of a bootstrap
script, so the entire system (packages, services, dotfiles) is reproducible,
rebuildable on any device, and rollback-able.

## Usage

On the running server:

```sh
cd ~/Sensible-NixOS-Setup
sudo nixos-rebuild switch --flake .#server
```

For a fresh install see [First install](#first-install-headless-server)
below.

## Layout

| Path | What it is |
| --- | --- |
| `flake.nix` | Entry point; pins nixpkgs 26.05 + home-manager |
| `hosts/server/` | Machine config: hostname, boot, timezone, firewall, tailscale |
| `hosts/server/hardware-configuration.nix` | **placeholder** — replace on install |
| `modules/base.nix` | Shared base: nix settings, GC, user, SSH |
| `modules/minecraft.nix` | Fabric dedicated server (systemd service + firewall) |
| `home/` | home-manager config — the declarative equivalent of `bootstrap.sh` |
| `files/p10k.zsh` | Powerlevel10k config, verbatim from the Fedora repo |

## The shell environment (same as sensible-fedora-setup)

- zsh as login shell, Oh My Zsh, Powerlevel10k (same `p10k.zsh`)
- Plugins: `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting` (last)
- zoxide (`cd` replacement), fzf (keybindings + fuzzy completion)
- yazi with the `y` cd-on-quit wrapper
- eza aliases: `ls`, `la`
- nvim as `$EDITOR`
- uv, tldr (tealdeer), gcc/gnumake
- pi coding agent + nodejs (declaratively via nixpkgs; `pi update --self` is
  a no-op — updates ride the nixpkgs input. Extensions/pi packages live in
  `~/.pi/agent/` as usual, e.g. `pi install npm:...`)

Differences from the Fedora version, on purpose:

- **Homebrew is gone** — Nix replaces it.
- `tldr` comes from nixpkgs (tealdeer) instead of `uv tool install`.
- No idempotence engineering needed — `nixos-rebuild switch` is always safe
  to re-run; that's the whole point.

## Ordering notes (why the config looks like it does)

- The p10k instant prompt is added with `initContent` + `lib.mkBefore`
  (home-manager 26.05's replacement for `initExtraFirst`) so it stays at the
  very top of the generated `~/.zshrc` — same reason it sits at the top of
  the Fedora `files/zshrc`.
- home-manager 26.05 removed `oh-my-zsh.customPkgs`, so the OMz custom
  directory (the two non-bundled plugins + the p10k theme) is assembled by
  a small `runCommand` derivation in `home/default.nix`. A side benefit:
  p10k is a real OMz theme again (`ZSH_THEME=powerlevel10k/powerlevel10k`),
  exactly like in the Fedora setup.
- `zsh-syntax-highlighting` stays last in `plugins=()` (official
  recommendation).

## First install (headless server)

On the NixOS installer ISO, as root (`sudo -i`):

```sh
# 1. Partition and mount: /mnt (root) and /mnt/boot (ESP)

# 2. Generate the hardware config for this machine:
nixos-generate-config --root /mnt

# 3. Grab this repo:
git clone https://github.com/Rico0319/Sensible-NixOS-Setup.git /mnt/etc/nixos/sns

# 4. Replace the placeholder with the real hardware config:
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/sns/hosts/server/

# 5. Install:
nixos-install --flake /mnt/etc/nixos/sns#server

# 6. Reboot, SSH in as ricoz
```

After first login: `passwd` (the initial password is `changeme`), then add
your SSH pubkey to `users.users.ricoz.openssh.authorizedKeys.keys` in
`modules/base.nix` and flip `PasswordAuthentication` to `false`.

## Minecraft server

A systemd service replicating the old `C:\Users\ricoz\mc-server\start.bat`
(see `modules/minecraft.nix`):

- Fabric server launcher pinned by hash — **byte-identical** to the Windows
  copy (MC 26.2, Loader 0.19.3, installer 1.1.2)
- `jdk21` (same as Prism's bundled "epsilon" runtime), `-Xmx4G`, `nogui`
- State (world, mods, config, server.properties, eula) lives in
  `/var/lib/minecraft`, owned by a dedicated `minecraft` user
- Port 25565/TCP open in the firewall

### One-time data migration (from the Windows box)

After the first rebuild the `minecraft` user and `/var/lib/minecraft` exist.
From Windows/WSL, copy everything except `start.bat`/`README.md`:

```sh
tar cf - -C /mnt/c/Users/ricoz/mc-server \
    world mods config libraries versions .fabric \
    server.properties eula.txt ops.json whitelist.json \
  | ssh server 'sudo tar xf - -C /var/lib/minecraft'
ssh server 'sudo chown -R minecraft:minecraft /var/lib/minecraft'
```

(`libraries`/`versions`/`.fabric` are included so the first start doesn't
re-download them — the launcher can fetch them itself if you skip them.)

### Daily operations

```sh
systemctl status minecraft         # up?
journalctl -u minecraft -f         # live console output
sudo systemctl stop minecraft      # clean stop (world saves; may take a while)
sudo systemctl restart minecraft   # after editing server.properties/mods
```

The server console (for commands like `op`, `whitelist add`) isn't wired up —
RCON is disabled in `server.properties` for parity with the old setup.
`ops.json`/`whitelist.json` were already migrated, so you're admin in-game;
if you ever need the console, enable RCON in `server.properties` and use
`mcrcon`, or `systemctl stop` + run the jar manually in tmux.

Backups: `systemctl stop minecraft`, then archive `/var/lib/minecraft/world`
(same rule as before — never open the old single-player save).

## Daily operations

- Rebuild: `sudo nixos-rebuild switch --flake .#server`
- Try without switching: `sudo nixos-rebuild test --flake .#server`
- Validate: `nix flake check`
- Rollback: `sudo nixos-rebuild switch --rollback` (or pick a generation in
  the boot menu — 10 are kept)
- Update inputs: `nix flake update && sudo nixos-rebuild switch --flake .#server`

## Customizing

- Shell: edit `home/default.nix`; prompt: edit `files/p10k.zsh`. The repo is
  the source of truth — rebuild applies changes. No copying back and forth
  (unlike the Fedora setup, where live edits had to be copied into the repo).
- New machine: add `hosts/<name>/`, add a `nixosConfigurations.<name>` entry
  in `flake.nix`, and reuse `modules/base.nix` + `home/`.

## Cockpit (web admin)

Same web admin panel Fedora Server ships. `http://server:9090`, log in with
your system credentials — manage services, logs, storage, networking, and
open a terminal from the browser. Over HTTPS with a self-signed cert by
default; also reachable over Tailscale.

Caveat: the "Software Updates" page is Fedora/dnf-specific. On NixOS,
updates are:

```sh
nix flake update && sudo nixos-rebuild switch --flake .#server
```

and rollbacks are `nixos-rebuild switch --rollback` (or a boot-menu
 generation) — strictly better than anything dnf ever gave you.

## Roadmap (home-server services)

- [x] Modded Minecraft — see "Minecraft server" above
- [ ] Jellyfin + external SSD mount (`fileSystems`, by-uuid, `nofail`)
- [ ] Immich for photos
- [x] Tailscale — already enabled; run `sudo tailscale up` once

## Headless caveat

The p10k/eza/yazi configs use Nerd Font glyphs. Over SSH that's fine as long
as the *local* terminal runs a Nerd Font.
