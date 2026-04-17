import "_common.justfile"

# install every tool declared in ~/.config/mise/config.toml
@bootstrap:
    mise install
    mise reshim
    mise current

# upgrade tools to newest compatible version (respects pins)
@upgrade:
    mise upgrade
    mise reshim
    mise current

