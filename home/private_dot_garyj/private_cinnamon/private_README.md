# Mint + Cinnamon Configurations

Folder contains configs for files for the Mint / Cinnamon desktop environment.

## Files

- `cinnamon.dconf` - Cinnamon desktop environment configurations
- `grouped_window_list_config.json` - Grouped Window List applet configurations (Start Menu😄)

## Importing / Exporting

export: `dconf dump /org/cinnamon/ | grep -v '^command-history' > cinnamon.dconf`
import: `dconf load /org/cinnamon/ < cinnamon.dconf`

Can also do other settings for `nemo`, `gtk`, and `gnome`.

Ref: <https://forums.linuxmint.com/viewtopic.php?t=187819>

### Export

```shell
dconf dump /org/cinnamon/ > cinnamon.dconf
dconf dump /org/nemo/ > nemo.dconf
dconf dump /org/gtk/ > gtk.dconf
dconf dump /org/gnome/ > gnome.dconf
```

### Import

```shell
dconf load /org/cinnamon/ < cinnamon.dconf
dconf load /org/nemo/ < nemo.dconf
dconf load /org/gtk/ < gtk.dconf
dconf load /org/gnome/ < gnome.dconf
```
