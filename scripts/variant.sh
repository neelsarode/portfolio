#!/usr/bin/env bash
#
# variant.sh — spin up isolated style-variant worktrees, each on its own port.
#
# Each variant is a full git branch + worktree, so it can diverge in BOTH tokens
# and structure without touching any other variant. Each runs its own dev server
# on its own port, so you compare by flipping browser tabs.
#
# Usage (run from the repo root, on any branch):
#   scripts/variant.sh new  <name> [base-branch]   Create + start a variant (auto port)
#   scripts/variant.sh list                         Show all variants, ports, status
#   scripts/variant.sh stop <name>                  Stop a variant's dev server
#   scripts/variant.sh start <name>                 (Re)start a stopped variant's server
#   scripts/variant.sh rm   <name>                  Stop + remove worktree + delete branch
#
# Conventions:
#   branch name : style/<name>
#   worktree    : .worktrees/<name>
#   base branch : design/modulabs-theme (override with the 2nd arg to `new`)
#   ports       : 4321 = main, 4322 = modulabs base, variants start at 4323
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WT_DIR="$ROOT/.worktrees"
LOG_DIR="$WT_DIR/.logs"
BASE_DEFAULT="design/modulabs-theme"
PORT_MIN=4323
RESERVED_PORTS="4321 4322"

mkdir -p "$LOG_DIR"

die() { echo "error: $*" >&2; exit 1; }

# Ports already claimed by reserved servers or existing variants.
used_ports() {
  echo $RESERVED_PORTS
  for f in "$WT_DIR"/*/.variant-port; do
    [ -f "$f" ] && cat "$f"
  done
}

next_port() {
  local used p=$PORT_MIN
  used=" $(used_ports | tr '\n' ' ') "
  while [[ "$used" == *" $p "* ]]; do p=$((p+1)); done
  echo "$p"
}

port_up() { curl -s -o /dev/null "http://localhost:$1/" 2>/dev/null; }

start_server() {
  local name="$1" wt="$2" port="$3"
  ( cd "$wt" && npm run dev -- --port "$port" >"$LOG_DIR/$name.log" 2>&1 & )
  echo "$port" >"$wt/.variant-port"
}

cmd_new() {
  local name="${1:-}" base="${2:-$BASE_DEFAULT}"
  [ -n "$name" ] || die "usage: variant.sh new <name> [base-branch]"
  [[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]] || die "name must be alphanumeric / . _ -"
  local branch="style/$name" wt="$WT_DIR/$name"
  [ -e "$wt" ] && die "worktree already exists: $wt"
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/$branch" && die "branch already exists: $branch"

  echo "→ creating worktree $wt (branch $branch, base $base)"
  git -C "$ROOT" worktree add -b "$branch" "$wt" "$base"

  echo "→ installing dependencies (isolated node_modules for a safe concurrent dev server)"
  ( cd "$wt" && npm install --no-audit --no-fund >"$LOG_DIR/$name.install.log" 2>&1 )

  local port; port="$(next_port)"
  echo "→ starting dev server on port $port"
  start_server "$name" "$wt" "$port"
  sleep 3
  if port_up "$port"; then
    echo "✓ variant '$name' live → http://localhost:$port  (branch $branch)"
  else
    echo "… server starting; check $LOG_DIR/$name.log — URL: http://localhost:$port"
  fi
}

cmd_list() {
  printf "%-16s %-26s %-7s %-7s %s\n" NAME BRANCH PORT STATUS URL
  printf "%-16s %-26s %-7s %-7s %s\n" main main 4321 "$(port_up 4321 && echo up || echo down)" http://localhost:4321
  printf "%-16s %-26s %-7s %-7s %s\n" modulabs design/modulabs-theme 4322 "$(port_up 4322 && echo up || echo down)" http://localhost:4322
  for d in "$WT_DIR"/*/; do
    local name; name="$(basename "$d")"
    [ "$name" = ".logs" ] && continue
    [ "$name" = "modulabs" ] && continue
    local port="—" status="—"
    [ -f "$d/.variant-port" ] && port="$(cat "$d/.variant-port")"
    [ "$port" != "—" ] && status="$(port_up "$port" && echo up || echo down)"
    printf "%-16s %-26s %-7s %-7s %s\n" "$name" "style/$name" "$port" "$status" "http://localhost:$port"
  done
}

cmd_stop() {
  local name="${1:-}"; [ -n "$name" ] || die "usage: variant.sh stop <name>"
  pkill -f "/.worktrees/$name/node_modules/.bin/astro" 2>/dev/null && echo "stopped '$name'" || echo "no running server for '$name'"
}

cmd_start() {
  local name="${1:-}"; [ -n "$name" ] || die "usage: variant.sh start <name>"
  local wt="$WT_DIR/$name"; [ -d "$wt" ] || die "no such variant: $name"
  local port; port="$([ -f "$wt/.variant-port" ] && cat "$wt/.variant-port" || next_port)"
  start_server "$name" "$wt" "$port"; sleep 3
  port_up "$port" && echo "✓ '$name' → http://localhost:$port" || echo "… starting; see $LOG_DIR/$name.log"
}

cmd_rm() {
  local name="${1:-}"; [ -n "$name" ] || die "usage: variant.sh rm <name>"
  cmd_stop "$name" || true
  git -C "$ROOT" worktree remove --force "$WT_DIR/$name" 2>/dev/null || true
  git -C "$ROOT" branch -D "style/$name" 2>/dev/null || true
  rm -f "$LOG_DIR/$name.log" "$LOG_DIR/$name.install.log"
  echo "removed variant '$name'"
}

sub="${1:-}"; shift || true
case "$sub" in
  new)   cmd_new "$@" ;;
  list)  cmd_list ;;
  stop)  cmd_stop "$@" ;;
  start) cmd_start "$@" ;;
  rm)    cmd_rm "$@" ;;
  *) echo "usage: variant.sh {new <name> [base] | list | stop <name> | start <name> | rm <name>}" ;;
esac
