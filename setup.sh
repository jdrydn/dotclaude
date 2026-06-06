#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLAUDE_DIR="${HOME}/.claude"

cleanup_dead_links() {
  local dest_dir="$1"
  for entry in "$dest_dir"/*; do
    [ -L "$entry" ] || continue
    target="$(readlink "$entry")"
    case "$target" in
      "$REPO_DIR"/*)
        if [ ! -e "$entry" ]; then
          echo "cleanup: removing dead symlink ${entry} -> ${target}"
          rm "$entry"
        fi
        ;;
    esac
  done
}

link_one() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "ok: ${dest} already linked"
      return
    fi
    echo "replace: ${dest} (was -> ${current})"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "skip: ${dest} exists and is not a symlink"
    return
  fi

  ln -s "$src" "$dest"
  echo "linked: ${dest} -> ${src}"
}

ensure_dest_dir() {
  local dest_dir="$1"
  if [ -L "$dest_dir" ]; then
    echo "error: ${dest_dir} is a symlink (-> $(readlink "$dest_dir")); remove it manually and re-run" >&2
    exit 1
  fi
  mkdir -p "$dest_dir"
}

copy_if_missing() {
  local src="$1"
  local dest="$2"

  if [ ! -f "$src" ]; then
    echo "skip: ${src} does not exist"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "ok: ${dest} exists, leaving alone"
    return
  fi

  cp "$src" "$dest"
  echo "copied: ${src} -> ${dest}"
}

# agents: each .md file under ./agents -> ~/.claude/agents/<name>.md
agents_src="${REPO_DIR}/agents"
agents_dest="${CLAUDE_DIR}/agents"
if [ -d "$agents_src" ]; then
  ensure_dest_dir "$agents_dest"
  cleanup_dead_links "$agents_dest"
  for src in "$agents_src"/*.md; do
    [ -f "$src" ] || continue
    link_one "$src" "${agents_dest}/$(basename "$src")"
  done
else
  echo "skip: ${agents_src} does not exist"
fi

# skills: each folder under ./skills -> ~/.claude/skills/<name>
skills_src="${REPO_DIR}/skills"
skills_dest="${CLAUDE_DIR}/skills"
if [ -d "$skills_src" ]; then
  ensure_dest_dir "$skills_dest"
  cleanup_dead_links "$skills_dest"
  for src in "$skills_src"/*/; do
    src="${src%/}"
    link_one "$src" "${skills_dest}/$(basename "$src")"
  done
else
  echo "skip: ${skills_src} does not exist"
fi

# rules: ./rules -> ~/.claude/rules/dotclaude (whole folder, single symlink)
rules_src="${REPO_DIR}/rules"
rules_dest="${CLAUDE_DIR}/rules"
if [ -d "$rules_src" ]; then
  ensure_dest_dir "$rules_dest"
  cleanup_dead_links "$rules_dest"
  link_one "$rules_src" "${rules_dest}/dotclaude"
else
  echo "skip: ${rules_src} does not exist"
fi

# CLAUDE.md: concat ./CLAUDE.md.d/*.md -> ./CLAUDE.md.d/generated.md, symlinked from ~/.claude/CLAUDE.md
claude_md_src="${REPO_DIR}/CLAUDE.md.d"
claude_md_out="${claude_md_src}/generated.md"
claude_md_dest="${CLAUDE_DIR}/CLAUDE.md"
if [ -d "$claude_md_src" ]; then
  parts=()
  for f in "$claude_md_src"/*.md; do
    case "$(basename "$f")" in
      generated.md|generated.*.md) continue ;;
    esac
    parts+=("$f")
  done

  if [ ${#parts[@]} -eq 0 ]; then
    echo "skip: no source *.md files in ${claude_md_src}"
  else
    tmp_out="$(mktemp "${claude_md_src}/.generated.tmp.XXXXXX")"
    trap 'rm -f "$tmp_out"' EXIT
    {
      for i in "${!parts[@]}"; do
        [ "$i" -gt 0 ] && printf '\n'
        cat "${parts[$i]}"
      done
    } > "$tmp_out"

    if [ -f "$claude_md_out" ] && cmp -s "$tmp_out" "$claude_md_out"; then
      echo "ok: ${claude_md_out} up to date (${#parts[@]} parts)"
      rm "$tmp_out"
    else
      if [ -f "$claude_md_out" ]; then
        ts="$(date '+%Y-%m-%d.%H-%M-%S')"
        backup="${claude_md_src}/generated.${ts}.md"
        mv "$claude_md_out" "$backup"
        echo "backed up: ${claude_md_out} -> ${backup}"
      fi
      mv "$tmp_out" "$claude_md_out"
      echo "built: ${claude_md_out} (${#parts[@]} parts)"
    fi
    trap - EXIT

    if [ -L "$claude_md_dest" ]; then
      current="$(readlink "$claude_md_dest")"
      if [ "$current" = "$claude_md_out" ]; then
        echo "ok: ${claude_md_dest} already linked"
      else
        rm "$claude_md_dest"
        ln -s "$claude_md_out" "$claude_md_dest"
        echo "relinked: ${claude_md_dest} -> ${claude_md_out} (was -> ${current})"
      fi
    elif [ -e "$claude_md_dest" ]; then
      echo "error: ${claude_md_dest} exists and is not a symlink; move it aside and re-run" >&2
      exit 1
    else
      ln -s "$claude_md_out" "$claude_md_dest"
      echo "linked: ${claude_md_dest} -> ${claude_md_out}"
    fi
  fi
else
  echo "skip: ${claude_md_src} does not exist"
fi

# settings.json / statusline-command.sh: copied (not symlinked) so they can be edited per-machine
copy_if_missing "${REPO_DIR}/settings.json" "${CLAUDE_DIR}/settings.json"
copy_if_missing "${REPO_DIR}/statusline-command.sh" "${CLAUDE_DIR}/statusline-command.sh"
