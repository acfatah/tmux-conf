# How To Persist Tmux Sessions

Tmux sessions live in memory. They are lost when the tmux server stops, for
example after a reboot, a WSL shutdown, or `tmux kill-server`.

This guide uses two plugins to fix that:

- **[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)** saves
  and restores sessions, windows, panes, layouts, and working directories.
- **[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)** runs
  resurrect automatically: it saves every 15 minutes and restores when tmux
  starts.

Both are installed with the
[Tmux Plugin Manager (TPM)](https://github.com/tmux-plugins/tpm).

## Requirements

- tmux 1.9 or newer (`tmux -V`)
- git
- bash

## 1. Install Tmux Plugin Manager

Clone TPM into the tmux plugins directory:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Add the following to the **bottom** of `~/.tmux.conf`. The `run` line must
stay the last line of the file:

```tmux
set -g @plugin 'tmux-plugins/tpm'

# Initialize TPM (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

Reload the config. Run this from inside tmux:

```bash
tmux source ~/.tmux.conf
```

## 2. Add tmux-resurrect

Add the plugin line above the `run` line in `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
```

Then press **`prefix` + `I`** (capital i) inside tmux to install it. The
default prefix is `Ctrl-b`.

### Save and restore manually

| Action  | Keys                  |
| ------- | --------------------- |
| Save    | `prefix` + `Ctrl-s`   |
| Restore | `prefix` + `Ctrl-r`   |

A message in the status bar confirms each action.

## 3. Add tmux-continuum (automatic save and restore)

Without continuum, you must remember to save before tmux stops. Continuum
does it for you.

```tmux
set -g @plugin 'tmux-plugins/tmux-continuum'

# Restore the last saved environment when the tmux server starts
set -g @continuum-restore 'on'

# Optional: save interval in minutes (default 15, 0 disables auto-save)
set -g @continuum-save-interval '15'
```

Press **`prefix` + `I`** again to install it.

## Optional settings

Put these above the `run` line as well.

```tmux
# Restore the visible text of each pane
set -g @resurrect-capture-pane-contents 'on'

# Restore Vim / Neovim sessions (needs vim-obsession, see below)
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'

# Restore extra programs besides the default list
set -g @resurrect-processes 'ssh htop "~npm run dev"'
```

- **Vim / Neovim sessions** require
  [tpope/vim-obsession](https://github.com/tpope/vim-obsession) and a
  running `:Obsess` in each editor.
- **`~` prefix** in `@resurrect-processes` matches any command that
  contains that text.

## Complete example `~/.tmux.conf`

```tmux
# ---- Plugins ----
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# ---- tmux-resurrect ----
set -g @resurrect-capture-pane-contents 'on'

# ---- tmux-continuum ----
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Initialize TPM (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

## Verify it works

1. Start tmux and create a couple of sessions, windows, and split panes.
2. Save with **`prefix` + `Ctrl-s`**.
3. Stop the server: `tmux kill-server`.
4. Start tmux again: `tmux`.
5. If continuum is on, your sessions come back on their own. Otherwise
   press **`prefix` + `Ctrl-r`**.

Check that continuum is saving:

```bash
tmux show-option -gv @continuum-save-interval
ls -lt ~/.local/share/tmux/resurrect/ | head
```

## Where saves are stored

- **`~/.local/share/tmux/resurrect/`** on recent versions (XDG path).
- **`~/.tmux/resurrect/`** on older versions.

Each save is a text file. The `last` symlink points to the one that restore
will use. To roll back to an older save, point `last` at a different file:

```bash
cd ~/.local/share/tmux/resurrect
ln -sf tmux_resurrect_<timestamp>.txt last
```

## Useful TPM keys

| Action                          | Keys                  |
| ------------------------------- | --------------------- |
| Install new plugins             | `prefix` + `I`        |
| Update plugins                  | `prefix` + `U`        |
| Remove plugins not in config    | `prefix` + `Alt-u`    |

## Troubleshooting

- **`prefix` + `I` does nothing.** Make sure the `run` line is the last line
  of `~/.tmux.conf`, then reload with `tmux source ~/.tmux.conf`.
- **Sessions are not restored on start.** Continuum restores only when the
  tmux server starts fresh. If another tmux server is already running,
  nothing is restored.
- **Restored panes show a shell instead of my program.** Only programs in
  the default list or in `@resurrect-processes` are restarted.
- **Auto-save stopped.** Continuum saves from the status bar refresh. A
  theme or plugin that overwrites `status-right` after continuum loads can
  break it; load continuum last among plugins.

## Gotchas

- **Running processes are not saved.** Resurrect restores the layout and
  restarts known commands. Unsaved state inside a program is lost.
- **Restore after a crash may use an old save.** Continuum saves on an
  interval, so up to 15 minutes of changes can be missing.
- **WSL:** `wsl --shutdown` or closing all WSL windows stops tmux. Continuum
  restores the sessions the next time you run `tmux`.
