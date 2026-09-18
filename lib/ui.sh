#!/usr/bin/env bash
# UI helpers. Uses gum/fzf when installed, falls back to plain bash prompts.
# Every function works in both modes so the menu never hard-breaks.

# Interactive widgets need a real TTY; without one (piped input, CI) fall back to
# plain read-based prompts so the script still works.
HAS_TTY=0; [ -t 0 ] && [ -r /dev/tty ] && HAS_TTY=1

HAS_GUM=0; [ "$HAS_TTY" = 1 ] && command -v gum >/dev/null 2>&1 && HAS_GUM=1
HAS_FZF=0; [ "$HAS_TTY" = 1 ] && command -v fzf >/dev/null 2>&1 && HAS_FZF=1

# Styling (non-interactive) is safe without a TTY.
HAS_GUM_STYLE=0; command -v gum >/dev/null 2>&1 && HAS_GUM_STYLE=1

C_PASS=42     # green
C_FAIL=203    # red
C_PROG=214    # orange
C_DIM=245     # grey
C_ACCENT=39   # blue

ui_header() {
  local title="$1" subtitle="${2:-}"
  if [ "$HAS_GUM_STYLE" = 1 ]; then
    gum style --border rounded --padding "0 2" --border-foreground $C_ACCENT \
      "$(gum style --bold --foreground $C_ACCENT "$title")" \
      "$(gum style --foreground $C_DIM "$subtitle")"
  else
    echo
    echo "=============================================="
    echo " $title"
    [ -n "$subtitle" ] && echo " $subtitle"
    echo "=============================================="
  fi
}

ui_info()  { if [ "$HAS_GUM_STYLE" = 1 ]; then gum style --foreground $C_ACCENT "$*"; else echo "$*"; fi; }
ui_ok()    { if [ "$HAS_GUM_STYLE" = 1 ]; then gum style --foreground $C_PASS   "$*"; else echo "$*"; fi; }
ui_err()   { if [ "$HAS_GUM_STYLE" = 1 ]; then gum style --foreground $C_FAIL   "$*"; else echo "$*"; fi; }
ui_dim()   { if [ "$HAS_GUM_STYLE" = 1 ]; then gum style --foreground $C_DIM    "$*"; else echo "$*"; fi; }

# ui_confirm "question" -> exit 0 if yes
ui_confirm() {
  if [ "$HAS_GUM" = 1 ]; then
    gum confirm "$1"
  else
    local a; read -rp "$1 [y/N] " a; [ "${a:-}" = "y" ]
  fi
}

# ui_menu "header" "key1|label1" "key2|label2" ... -> echoes chosen key
ui_menu() {
  local header="$1"; shift
  local -a labels=() keys=()
  local item
  for item in "$@"; do
    keys+=("${item%%|*}")
    labels+=("${item#*|}")
  done

  if [ "$HAS_GUM" = 1 ]; then
    local chosen
    chosen=$(printf '%s\n' "${labels[@]}" | gum choose --header "$header" --height 12) || return 1
    local i
    for i in "${!labels[@]}"; do
      [ "${labels[$i]}" = "$chosen" ] && { echo "${keys[$i]}"; return 0; }
    done
    return 1
  fi

  echo >&2
  echo "$header" >&2
  local i
  for i in "${!labels[@]}"; do
    printf '%3d) %s\n' "$((i+1))" "${labels[$i]}" >&2
  done
  local n; read -rp "Choice: " n
  case "${n:-}" in
    ''|*[!0-9]*) return 1 ;;
  esac
  local idx=$((n-1))
  [ "$idx" -ge 0 ] && [ "$idx" -lt "${#keys[@]}" ] || return 1
  echo "${keys[$idx]}"
}

# ui_pick "header" < tab-separated "key<TAB>display" lines -> echoes chosen key
ui_pick() {
  local header="$1"
  local input; input=$(cat)
  [ -n "$input" ] || return 1

  if [ "$HAS_FZF" = 1 ]; then
    local line
    line=$(printf '%s\n' "$input" | fzf --with-nth=2.. --delimiter='\t' \
      --header="$header" --height=90% --reverse --ansi) || return 1
    printf '%s' "${line%%$'\t'*}"
    return 0
  fi

  if [ "$HAS_GUM" = 1 ]; then
    local display chosen
    display=$(printf '%s\n' "$input" | cut -f2-)
    chosen=$(printf '%s\n' "$display" | gum choose --header "$header" --height 20) || return 1
    printf '%s\n' "$input" | awk -F'\t' -v c="$chosen" '{d=$0; sub(/^[^\t]*\t/,"",d); if (d==c) {print $1; exit}}'
    return 0
  fi

  echo >&2
  echo "$header" >&2
  printf '%s\n' "$input" | cut -f2- | nl -w3 -s') ' >&2
  # stdin already consumed by `cat` above, so read the answer from the terminal.
  local n
  if (exec 3</dev/tty) 2>/dev/null; then
    read -rp "Number (blank to cancel): " n < /dev/tty
  else
    read -rp "Number (blank to cancel): " n
  fi
  [ -n "${n:-}" ] || return 1
  case "$n" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s\n' "$input" | sed -n "${n}p" | cut -f1
}

# ui_bar done total -> "[####....] 4/23"
ui_bar() {
  local done_n="$1" total="$2" width=24 filled=0 i s=""
  [ "$total" -gt 0 ] && filled=$(( done_n * width / total ))
  for ((i=0;i<width;i++)); do [ "$i" -lt "$filled" ] && s+="#" || s+="."; done
  printf '[%s] %d/%d' "$s" "$done_n" "$total"
}

# ui_status_tag pass|fail|"in progress"|- -> colored short tag
ui_status_tag() {
  local text color
  case "$1" in
    pass)          text="done "; color=$C_PASS ;;
    fail)          text="open "; color=$C_FAIL ;;
    "in progress") text="doing"; color=$C_PROG ;;
    *)             text="new  "; color=$C_DIM ;;
  esac
  # "--" stops gum parsing a leading-dash label as a flag.
  if [ "$HAS_GUM_STYLE" = 1 ]; then
    gum style --foreground "$color" -- "$text"
  else
    echo "$text"
  fi
}
