#!/usr/bin/env bash
# Repair a dangling `last` symlink in the tmux-resurrect save directory.
#
# save.sh names each save file to the second (date +%Y%m%dT%H%M%S). If two
# saves land in the same second they share one filename: the first points
# `last` at it, the second finds the file identical to `last` and deletes it
# (save.sh:247-251). The result is `last` -> a file that no longer exists.
# restore.sh:30-36 tests [ ! -f ], which is true for a dangling symlink, so a
# restore in that state silently restores nothing at all.
#
# Run at config load (before continuum's auto-restore) and after every save.

set -u

dir="${HOME}/.local/share/tmux/resurrect"
link="${dir}/last"

# Nothing to do if the link is absent or already resolves.
[ -L "$link" ] || exit 0
[ -e "$link" ] && exit 0

newest="$(ls -t "${dir}"/tmux_resurrect_*.txt 2>/dev/null | head -1)"
[ -n "$newest" ] || exit 0

ln -fs "$(basename "$newest")" "$link"
