#!/data/data/com.termux/files/usr/bin/bash
# push.sh                    -> push every repo with changes (guarded)
# push.sh Physics "message"  -> push one repo
# FORCE=1 push.sh ...        -> allow >MAXDEL missing files (default 20)
BASE=~/storage/shared/Git
MAXDEL=${MAXDEL:-20}
repos=${1:-$(ls -d "$BASE"/*/.git 2>/dev/null | xargs -n1 dirname | xargs -n1 basename)}
for r in $repos; do
  cd "$BASE/$r" 2>/dev/null || { echo "SKIP $r: folder not found"; continue; }
  [ -d .git ] || { echo "SKIP $r: not a git repo"; continue; }
  if ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then
    echo "SKIP $r: HEAD is broken (no commits). Fix before pushing."; continue
  fi
  del=$(git status --porcelain --untracked-files=no | grep -c '^ D')
  if [ "$del" -gt "$MAXDEL" ] && [ -z "$FORCE" ]; then
    echo "SKIP $r: $del tracked files missing locally (stale or broken?). FORCE=1 if intentional."; continue
  fi
  [ -z "$(git status --porcelain)" ] && continue
  big=$(git ls-files -m -o --exclude-standard -z | while IFS= read -r -d '' f; do
          [ -f "$f" ] && [ "$(stat -c %s "$f")" -gt 95000000 ] && echo "$f"
        done)
  if [ -n "$big" ]; then
    echo "SKIP $r: file(s) over 95 MB (GitHub limit 100 MB):"; echo "$big"; continue
  fi
  echo "== $r =="
  git pull --rebase --autostash || { echo "SKIP $r: pull failed, not pushing"; continue; }
  git add -A
  git diff --cached --quiet && { echo "nothing to commit"; continue; }
  git commit -q -m "${2:-notes: $(date '+%Y-%m-%d %H:%M')}"
  git push || echo "PUSH FAILED for $r"
done
