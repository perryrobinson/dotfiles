# Investigate: Dotfiles Symlink Setup

`~/.bash_paths` (and likely other dotfiles) are not symlinked to their sources in `~/dotfiles/bash/`.
They should be, so that edits to the dotfiles repo are reflected live without manual copying.

## What to check
- Which files in `~/dotfiles/bash/` are supposed to be symlinked to `~/`
- Whether `install.sh` is meant to set these up and why it hasn't been run / didn't work
- Current state: `~/.bash_paths` is a plain file, not a symlink to `~/dotfiles/bash/bash_paths`

## Why it matters
Changes made directly to `~/.bash_paths` (e.g. adding tool PATHs) won't be reflected in the dotfiles repo,
making the repo out of sync with the live config.
