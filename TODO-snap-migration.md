# Snap to Flatpak/APT Migration

Migrating snap packages to Flatpak or native alternatives on Debian.

## Flatpak Replacements

- [ ] **discord** — `flatpak install flathub com.discordapp.Discord`
- [ ] **ferdium** — `flatpak install flathub org.ferdium.Ferdium`
- [ ] **obs-studio** — `flatpak install flathub com.obsproject.Studio`
- [ ] **slack** — `flatpak install flathub com.slack.Slack`
- [ ] **spotify** — `flatpak install flathub com.spotify.Client`
- [ ] **telegram-desktop** — `flatpak install flathub org.telegram.desktop`
- [ ] **dbeaver-ce** — `flatpak install flathub io.dbeaver.DBeaverCommunity`
- [ ] **obsidian** — `flatpak install flathub md.obsidian.Obsidian`
- [ ] **sublime-text** — `flatpak install flathub com.sublimetext.three`

## APT/Cargo Replacements

- [ ] **dust** — `sudo apt install du-dust` or `cargo install du-dust`
- [ ] **pdftk** — `sudo apt install pdftk`
- [ ] **just** — `sudo apt install just` or install via mise

## To Decide

- [ ] **ghostty** — build from source / apt repo (already managed separately?)
- [ ] **snapcraft** — drop entirely if no longer building snaps

## Cleanup

- [ ] Remove snap packages from `run_onchange_before_10_install-packages.sh.tmpl`
- [ ] Remove `run_onchange_before_08_enable-snapcrat.sh.tmpl` (snap enablement script)
- [ ] Remove snap desktop file copy logic from install script
- [ ] `sudo apt remove snapd` once all snaps are migrated
