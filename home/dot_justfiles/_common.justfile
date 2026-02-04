set dotenv-load := false
set export := true

# list all available recipes
[private]
@default:
    just --justfile {{ justfile() }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile() }} --fmt
