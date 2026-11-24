#!/usr/bin/env bash
# Copy stdin to the system clipboard, with whichever tool this machine has.
#
# tmux pipes copied text here: the copy-mode `y` binding, and the mouse
# bindings through `copy-command`. One script keeps the same tmux.conf
# working on WSL and on plain Linux. Tools are tried in this order, and
# the first that succeeds wins:
#
#   clip.exe   WSL. Windows' own clipboard tool, reached through interop
#              on the Windows PATH, or at its fixed path when the PATH is
#              off (appendWindowsPath=false in /etc/wsl.conf). It expects
#              UTF-16LE, so iconv converts first; without that, non-ASCII
#              characters (accents, emoji, box-drawing) come out garbled.
#              Tried first, because WSL may also have xclip or wl-copy,
#              which reach only the WSLg clipboard.
#   wl-copy    Wayland, Ubuntu's default desktop session.
#   xclip      X11.
#   xsel       X11, when xclip is missing.
#
# The text is saved to a temporary file first, so each attempt reads it
# from the start. A tool that is installed but has no display to talk to
# (wl-copy without Wayland, xclip without X) fails, and the next one runs.
#
# Exits 1 when no tool worked. tmux still keeps the text in its paste
# buffer, and still sends it to the terminal as OSC 52 when the terminal
# supports that (set-clipboard), so a copy is never lost outright.

set -u

tmp="$(mktemp)" || exit 1
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"

for clip in clip.exe /mnt/c/Windows/System32/clip.exe; do
  if command -v "$clip" >/dev/null 2>&1; then
    iconv -f UTF-8 -t UTF-16LE <"$tmp" | "$clip" && exit 0
  fi
done

# Their output goes to /dev/null: xclip and wl-copy stay running in the
# background to serve the selection, and an open stdout would keep tmux
# waiting on the job.
if command -v wl-copy >/dev/null 2>&1; then
  wl-copy <"$tmp" >/dev/null 2>&1 && exit 0
fi
if command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard -in <"$tmp" >/dev/null 2>&1 && exit 0
fi
if command -v xsel >/dev/null 2>&1; then
  xsel --clipboard --input <"$tmp" >/dev/null 2>&1 && exit 0
fi

exit 1
