# Agent identities

Scoped identities for coding agents. Your own shell, gh login and signing key are
never touched; you opt in per invocation:

    lara claude --dangerously-skip-permissions
    lara zsh                      # interactive shell as Lara, for debugging her setup

Without the wrapper, agents run as you (signed commits, your gh token). That is the
default and the common case; reach for an agent identity when you want the work
attributed to a bot and its GitHub reach limited to the repos its App is installed on.

## Layout

    ~/bin/agents/
    ├── lara                  entry point: per-agent config, then exec
    └── lib/
        ├── identity.sh       the env swap (sourced by the entry point)
        ├── gh-token.sh       <org> -> short-lived App installation token
        ├── git-credential.sh git credential helper, org-scoped
        ├── verify-op.sh      one-off check that the SA scope is tight
        └── shim/gh           PATH shim so `gh` acts as the bot

Code lives here and is managed by chezmoi. Machine-local state stays out of the way
in `~/.config/gj_agents/<agent>/`:

    token       the 1Password service-account token, written by `chezmoi apply`
    gh/         whatever gh writes for this identity

## Do not run `chezmoi apply` from inside an agent

`lib/shim` is on `PATH` for the whole agent process tree, so chezmoi's `lookPath "gh"`
resolves to the shim and bakes its path into your personal git config. Run chezmoi
from your own shell.

## Adding another agent

Copy `lara`, change the five `AGENT_*` values, add a deploy script for its token
under `home/.chezmoiscripts/linux/`. Nothing in `lib/` needs touching.

## Provisioning Lara on a new box

Account-level, once, shared by all boxes:

- The "Agent Lara" GitHub App exists, is installed on each org whose repos she
  should reach, and its `app_id` + `private_key` are in the AGLara vault.
- The Lara 1Password service account has read access to AGLara.

Per box:

1. Check the service account scope (run as yourself, in a clean shell):

       ~/bin/agents/lib/verify-op.sh AGLara 'op://Personal/1P Service Account - Lara/password'

2. Run `chezmoi apply` to materialize the token.

3. In a scratch repo, confirm `lara claude ...` produces a commit authored
   `agent-lara[bot]`, pushes, and opens a PR as `agent-lara[bot]`.

Commits made under an agent identity are deliberately **unsigned**: your signing key
is the only one on the box, and signing with it would claim the bot's work as yours.
