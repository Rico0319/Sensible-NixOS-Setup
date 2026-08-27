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

## Roadmap (home-server services)

- [ ] Modded Minecraft via [nix-minecraft](https://github.com/Infinidoge/nix-minecraft)
- [ ] Jellyfin + external SSD mount (`fileSystems`, by-uuid, `nofail`)
- [ ] Immich for photos
- [x] Tailscale — already enabled; run `sudo tailscale up` once

## Headless caveat

The p10k/eza/yazi configs use Nerd Font glyphs. Over SSH that's fine as long
as the *local* terminal runs a Nerd Font.
