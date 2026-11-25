#!/usr/bin/env bash

curl -LsSf https://astral.sh/uv/install.sh | sh

uv python install
uv tool install ruff
uv tool install 'pyright[nodejs]'
uv tool install bandit
uv tool install safety
uv tool install 'scancode-toolkit[full]'


