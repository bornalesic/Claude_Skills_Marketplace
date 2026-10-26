#!/usr/bin/env bash
# Creates one git worktree, branch and .env.local per workstream, so several
# Claude Code agents can work in parallel without sharing a checkout, a port or a database.
#
# Usage:
#   scripts/setup-worktrees.sh                 # every workstream (w0-foundation ... w8-qa)
#   scripts/setup-worktrees.sh w1-auth w2-mcp  # only these
#   scripts/setup-worktrees.sh main            # only the .env.local of the main checkout
#
# Worktrees go to ../upskillzz-wt/<id> next to the main checkout (override with WT_DIR=...).
# Branches are ws/<id>, created from main. Safe to re-run: existing worktrees and
# existing .env.local files are left untouched.
#
# Works with the bash 3.2 that ships with macOS.

set -euo pipefail

ALL_WORKSTREAMS="w0-foundation w1-auth w2-mcp w3-content w4-payments w5-web w6-tutorial w7-infra w8-qa"

usage() {
  echo "Usage: $0 [main | <workstream> ...]"
  echo "Workstreams: $ALL_WORKSTREAMS"
}

index_of() {
  case "$1" in
    main) echo 0 ;;
    w0-foundation) echo 1 ;;
    w1-auth) echo 2 ;;
    w2-mcp) echo 3 ;;
    w3-content) echo 4 ;;
    w4-payments) echo 5 ;;
    w5-web) echo 6 ;;
    w6-tutorial) echo 7 ;;
    w7-infra) echo 8 ;;
    w8-qa) echo 9 ;;
    *) echo "" ;;
  esac
}

random_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 | tr -d '\n/+=' | cut -c1-48
  else
    head -c 64 /dev/urandom | base64 | tr -d '\n/+=' | cut -c1-48
  fi
}

# write_env <checkout dir> <workstream> <index>
write_env() {
  local dir="$1" ws="$2" n="$3"
  local target="$dir/.env.local"
  local example="$dir/.env.example"

  if [ -f "$target" ]; then
    echo "  .env.local already exists, left unchanged (compare it with .env.example after rebasing)"
    return
  fi
  if [ ! -f "$example" ]; then
    echo "  no .env.example in $dir, skipped .env.local"
    return
  fi

  local web=$((3000 + n * 10))
  local mcp=$((web + 1))
  local db
  if [ "$ws" = "main" ]; then db="upskillzz"; else db="upskillzz_${ws%%-*}"; fi
  local app="http://localhost:$web"

  awk -v ws="$ws" -v web="$web" -v mcp="$mcp" -v app="$app" -v db="$db" -v secret="$(random_secret)" '
    BEGIN {
      o["WORKSTREAM"] = ws
      o["WEB_PORT"] = web
      o["MCP_PORT"] = mcp
      o["APP_URL"] = app
      o["MCP_URL"] = "http://localhost:" mcp "/mcp"
      o["DATABASE_URL"] = "postgres://upskillzz:upskillzz@localhost:5432/" db
      o["BETTER_AUTH_URL"] = app
      o["BETTER_AUTH_SECRET"] = secret
      o["AUTH_ISSUER"] = app "/api/auth"
      o["AUTH_JWKS_URL"] = app "/api/auth/jwks"
    }
    /^[A-Z0-9_]+=/ {
      k = substr($0, 1, index($0, "=") - 1)
      if (k in o) { print k "=" o[k]; seen[k] = 1; next }
    }
    { print }
    END { for (k in o) if (!(k in seen)) print k "=" o[k] }
  ' "$example" > "$target"

  echo "  wrote .env.local (web :$web, mcp :$mcp, database $db)"
}

main_root="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | sed 's#/\.git$##')" || true
if [ -z "${main_root:-}" ] || [ ! -d "$main_root" ]; then
  echo "Run this inside the upskillzz git repository." >&2
  exit 1
fi

if ! git -C "$main_root" rev-parse --verify --quiet refs/heads/main >/dev/null; then
  echo "There is no 'main' branch yet. Commit the skeleton first:" >&2
  echo "  git init -b main && git add -A && git commit -m 'chore: planning skeleton'" >&2
  exit 1
fi

wt_dir="${WT_DIR:-$(cd "$main_root/.." && pwd)/upskillzz-wt}"
targets="${*:-$ALL_WORKSTREAMS}"

for ws in $targets; do
  case "$ws" in -h|--help) usage; exit 0 ;; esac
  n="$(index_of "$ws")"
  if [ -z "$n" ]; then
    echo "Unknown workstream: $ws" >&2
    usage >&2
    exit 1
  fi

  if [ "$ws" = "main" ]; then
    echo "main: $main_root"
    write_env "$main_root" main 0
    continue
  fi

  mkdir -p "$wt_dir"
  dir="$wt_dir/$ws"
  branch="ws/$ws"
  echo "$ws: $dir (branch $branch)"

  if [ -d "$dir" ]; then
    echo "  worktree already exists"
  elif git -C "$main_root" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$main_root" worktree add --quiet "$dir" "$branch"
    echo "  created worktree on existing branch"
  else
    git -C "$main_root" worktree add --quiet -b "$branch" "$dir" main
    echo "  created worktree and branch from main"
  fi

  write_env "$dir" "$ws" "$n"
done

echo
echo "Next: cd into a worktree and run 'claude'. Prompts are in docs/agents/README.md."
