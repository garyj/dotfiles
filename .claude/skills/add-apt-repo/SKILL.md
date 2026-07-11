---
name: add-apt-repo
description: Use when adding or editing a third-party apt repository installer under home/.chezmoiscripts/linux/personal/. Covers the add-apt-repo template helper, which exemplars to copy, and why command -v guards must never be added to these scripts.
---

# Vendor apt repo installers

New third-party apt repos go in `home/.chezmoiscripts/linux/personal/` as
`run_onchange_before_install-<name>.sh.tmpl`. Use the `add-apt-repo` helper
(`home/.chezmoitemplates/add-apt-repo`) via `{{ template "add-apt-repo" . }}`
— it handles keyring + sources atomically at the correct 0644 mode. Model
after `install-spotify.sh.tmpl` or `install-dbeaver.sh.tmpl`. Scripts with
extra requirements (debsig-verify, fingerprint checks, codename substitution)
keep their bespoke flow — see `install-onepassword.tmpl`,
`install-browser-firefox-dev.tmpl`, `install-ghostty.sh.tmpl` as exemplars.

Do not add `command -v <binary>` guards in these scripts: `run_onchange_`
already gates on template hash, and a secondary guard silently blocks
legitimate updates (new key URL, changed sources line) from reaching an
already-installed machine.
