#!/usr/bin/env bash

# Install uv into ~/.local/bin and do not modify our bash/zsh rc files
curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh

UV_PATH="$HOME/.cargo/bin" # uv's default install path

# if adding a new default version remember to update the .common_aliases file
"$UV_PATH"/uv python install 3.11
"$UV_PATH"/uv python install 3.12
"$UV_PATH"/uv python install 3.13

"$UV_PATH"/uv tool install --python=3.12 cookiecutter
"$UV_PATH"/uv tool install --python=3.12 djlint
"$UV_PATH"/uv tool install --python=3.12 git-changelog
"$UV_PATH"/uv tool install --python=3.12 ipython
"$UV_PATH"/uv tool install --python=3.12 llm
"$UV_PATH"/uv tool install --python=3.12 mkdocs --with mkdocs-material
"$UV_PATH"/uv tool install --python=3.12 poetry --with poetry-plugin-export
"$UV_PATH"/uv tool install --python=3.12 pre-commit --with pre-commit-uv
"$UV_PATH"/uv tool install --python=3.12 tbump
"$UV_PATH"/uv tool install --python=3.12 tox --with tox-uv
