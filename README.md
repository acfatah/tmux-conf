# tmux-conf

My tmux configuration, tuned for WSL and for working with Claude Code in
tmux.

## Features

- **Prefix `Ctrl-a`** (screen-style), which frees `Ctrl-b` for Vim's page-up.
- **Persistent sessions** with tmux-resurrect and tmux-continuum: saves every
  15 minutes and restores when the tmux server starts. See
  [docs/persist-sessions.md](docs/persist-sessions.md).
- **Resurrect repair script.** `resurrect-fix-last.sh` fixes a dangling
  `last` symlink that makes restore silently do nothing.
- **Automatic window names.** Claude Code panes take the task summary that
  Claude writes into the pane title; other panes take the current folder
  name.
- **Pane border labels** with the pane's name and git branch, so split panes
  and forked Claude sessions stay distinguishable.
- **Copy to the Windows clipboard** from vi copy mode (`y`), via `clip.exe`.
- **Terminal tab title** set to `<session>: <current path>`.

## Files

| File | Purpose |
| --- | --- |
| `tmux.conf` | The configuration; `~/.tmux.conf` links here |
| `resurrect-fix-last.sh` | Repairs resurrect's `last` symlink; `~/.tmux/resurrect-fix-last.sh` links here |
| `docs/persist-sessions.md` | Guide to persisting sessions with resurrect and continuum |

## Install

1. Clone the repo and install TPM:

   ```bash
   git clone https://github.com/acfatah/tmux-conf.git ~/personal/tmux-conf
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Link the files into place. Back up any existing `~/.tmux.conf` first.

   ```bash
   mkdir -p ~/.tmux
   ln -s ~/personal/tmux-conf/tmux.conf ~/.tmux.conf
   ln -s ~/personal/tmux-conf/resurrect-fix-last.sh ~/.tmux/resurrect-fix-last.sh
   ```

3. Start tmux, then press `prefix` + `I` (capital i) to install the plugins.

## Automatic window names

A window renamed by hand keeps its name, because renaming turns
`automatic-rename` off for that window. To hand it back to automatic naming,
run this inside the window:

```bash
tmux set -w automatic-rename on
```

## Gotchas

- **The links depend on the repo path.** If you move the repo, re-create both
  symlinks.
- **Some tools replace symlinks.** `cp` onto `~/.tmux.conf`, or an editor
  that saves by writing a new file, turns the link into a regular file, and
  the repo stops seeing changes.
- **WSL only:** the clipboard binding needs `clip.exe` on the Windows `PATH`.
- **The prefix is `Ctrl-a` here**, while the guide in `docs/` uses the
  default, `Ctrl-b`.
