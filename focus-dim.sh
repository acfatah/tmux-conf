#!/usr/bin/env bash
# Dim or undim one tmux session, so a terminal window that is not the
# focused app window looks faded. Called from the client-focus-out,
# client-focus-in, client-attached and client-session-changed hooks in
# tmux.conf.
#
# Usage: focus-dim.sh dim|undim SESSION_ID CLIENT_NAME
#
# Why per session and not global: with several terminal windows open,
# each attached to its own session, global options made them all look
# the same. Worse, switching between two of them can deliver the new
# window's focus-in before the old window's focus-out, which left the
# window in use dimmed.
#
# How it works:
#   dim     sets session and window options on SESSION_ID only: grey
#           status bar, grey window list, lighter pane backgrounds with
#           grey text (the active pane stays darker than the others), and
#           @unfocused, which pane-active-border-style checks to fade the
#           active border. It skips the dim when another client showing
#           the same session still has focus, so a session opened in two
#           windows by accident stays bright while either one is in use.
#   undim   unsets those same options, so the global values in tmux.conf
#           show through again. The focused colors live only in
#           tmux.conf; this script never repeats them.
#
# All option changes go out as one tmux command, so the session never
# shows half of the dim.

set -u

mode="${1:?usage: focus-dim.sh dim|undim SESSION_ID CLIENT_NAME}"
session="${2:?missing SESSION_ID}"
client="${3:-}"

# Dimmed colors. The focused ones are the globals in tmux.conf.
dim_status='bg=#0a1417,fg=#3b6670'
dim_window_status='fg=#3b6670'
dim_window_status_current='bg=#1f3a40,fg=#5eaab5'
dim_pane='bg=colour236,fg=colour242'
dim_pane_active='bg=colour234,fg=colour242'

windows="$(tmux list-windows -t "$session" -F '#{window_id}')" || exit 1

case "$mode" in
dim)
    # Another client on this session is still focused: leave it bright.
    if tmux list-clients -t "$session" -F '#{client_name} #{client_flags}' |
        awk -v self="$client" '$1 != self && $2 ~ /(^|,)focused(,|$)/ { found = 1 }
            END { exit !found }'; then
        exit 0
    fi
    args=(set -t "$session" @unfocused 1
        \; set -t "$session" status-style "$dim_status")
    for w in $windows; do
        args+=(\; set -w -t "$w" window-style "$dim_pane"
            \; set -w -t "$w" window-active-style "$dim_pane_active"
            \; set -w -t "$w" window-status-style "$dim_window_status"
            \; set -w -t "$w" window-status-current-style "$dim_window_status_current")
    done
    ;;
undim)
    args=(set -u -t "$session" @unfocused
        \; set -u -t "$session" status-style)
    for w in $windows; do
        args+=(\; set -wu -t "$w" window-style
            \; set -wu -t "$w" window-active-style
            \; set -wu -t "$w" window-status-style
            \; set -wu -t "$w" window-status-current-style)
    done
    ;;
*)
    echo "focus-dim.sh: unknown mode '$mode'" >&2
    exit 2
    ;;
esac

tmux "${args[@]}"
