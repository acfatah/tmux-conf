# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## What this repo is

A personal tmux configuration for WSL, tuned for running Claude Code inside
tmux. There is no build or test suite. The live files are symlinks into this
repo:

- `~/.tmux.conf` -> `tmux.conf`
- `~/.tmux/resurrect-fix-last.sh` -> `resurrect-fix-last.sh`

So an edit here is live as soon as the config is reloaded. Never `cp` over
those paths; that replaces the symlink and the repo stops seeing changes.

## Commands

```bash
tmux source-file -n tmux.conf          # parse-only syntax check, applies nothing
tmux source ~/.tmux.conf               # reload the live config (inside tmux)
shellcheck resurrect-fix-last.sh       # lint the repair script
bash -n resurrect-fix-last.sh          # syntax check the repair script
tmux display -p '<format>'             # evaluate a format string in the current pane
```

Test a `#{...}` format with `tmux display -p` before putting it into
`automatic-rename-format` or `pane-border-format`.

## How `tmux.conf` fits together

Order in `tmux.conf` matters:

1. **Plugin declarations** (`@plugin`) and plugin options (`@continuum-*`,
   `@resurrect-*`) come first, because TPM reads them when it runs.
2. **`run-shell '~/.tmux/resurrect-fix-last.sh'`** runs before TPM, so the
   resurrect `last` symlink is repaired before continuum's auto-restore fires.
3. **The `C-a` prefix** must be set before TPM: tmux-sensible reads the prefix
   at load time and binds `prefix a` to last-window.
4. **Plain options** (pane styles, the clipboard binding, titles, auto naming,
   pane borders) come next. tmux-sensible does not touch any of them, and it
   mostly sets options only when they still hold tmux's default, so placing
   them before TPM costs nothing.
5. **`run '~/.tmux/plugins/tpm/tpm'`** stays the last line. tmux-continuum
   appends its autosave trigger to `status-right` when it loads, so a
   `status-right` or theme set after this line would silently stop autosaves.

### Session persistence

tmux-resurrect saves and restores layouts; tmux-continuum saves every 15
minutes and restores at server start. `resurrect-fix-last.sh` works around a
resurrect bug: two saves in the same second leave `last` as a dangling
symlink, and restore then silently does nothing. The script runs at config
load and from `@resurrect-hook-post-save-all`.

`@resurrect-processes` matches against the saved command line. A bare name
matches only a prefix of it; a leading `~` matches anywhere, which is needed
for programs saved with an absolute path (such as snap's `glow`). Check
`~/.local/share/tmux/resurrect/last` to see how a program is recorded.

### Window and pane names

`automatic-rename-format` and `pane-border-format` share one rule: if the
pane runs `claude`, show the pane title (Claude Code's task summary) with its
leading glyph stripped by `s/^[^ ]+ //`; otherwise show the basename of the
current directory. The pane border also appends the git branch via
`#(git -C ...)`, which refreshes every `status-interval`. Keep the two
formats in step when changing either one.

## Platform assumptions

- **WSL:** the copy-mode `y` binding pipes through `iconv` to UTF-16LE and
  then to `clip.exe`. It runs under `sh -c`, so shell aliases are not
  available there.
- **Prefix is `Ctrl-a`** in this config, while `docs/persist-sessions.md`
  is written for the default `Ctrl-b`.

## Writing style

Comments in `tmux.conf` explain *why* a setting exists and how it works,
often in several lines. Follow that style for new settings. Markdown in this
repo is hard-wrapped at 80 columns.

