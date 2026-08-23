# Working on the chezmoi source repo. Machine-level recipes live in ~/justfile
# (rendered from home/justfile); this one shadows it inside a checkout.

set dotenv-load := false
set unstable

# list available recipes
[private]
@default:
    just --list

# vendored skills: check | sync [--dry-run] [--latest] [NAME]; run `just skills --help` for the rest
[group("skills")]
skills *ARGS:
    uv run scripts/vendor_skill.py {{ ARGS }}

# preview what chezmoi would change on this machine
[group("chezmoi")]
diff *ARGS:
    chezmoi diff {{ ARGS }}

# apply the source state to this machine
[group("chezmoi")]
apply *ARGS:
    chezmoi apply {{ ARGS }}

# install the prek git hooks, once per clone
[group("dev")]
hooks:
    prek install

# run every git hook against every file
[group("dev")]
pc *ARGS:
    prek run --all-files {{ ARGS }}

# format this justfile
[group("dev")]
fmt:
    just --fmt
