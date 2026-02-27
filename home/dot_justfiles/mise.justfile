import "_common.justfile"

# bootstrap mise by installing configured language versions
@bootstrap:
    mise install golang
    mise install node
    mise install rust
    mise install bun
    mise reshim
    mise current
    mise list

# install latest language versions and refresh shims
@upgrade:
    mise install
    mise reshim
