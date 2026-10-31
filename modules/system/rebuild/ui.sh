# Общее для rebuild, desktop-env и bash-theme: цвета, сообщения и откат
# пульта, если пересборка после его правки не удалась.

c_info=$'\e[38;5;117m' c_ok=$'\e[38;5;156m' c_warn=$'\e[38;5;229m'
c_err=$'\e[38;5;203m' c_dim=$'\e[38;5;248m' c_off=$'\e[0m'

info() { printf '%s  %s%s\n' "$c_info" "$*" "$c_off"; }
ok() { printf '%s  %s%s\n' "$c_ok" "$*" "$c_off"; }
warn() { printf '%s  %s%s\n' "$c_warn" "$*" "$c_off"; }
dim() { printf '%s  %s%s\n' "$c_dim" "$*" "$c_off"; }
fail() {
  printf '%s  ✗ %s%s\n' "$c_err" "$*" "$c_off" >&2
  exit 1
}

# Есть ли $1 среди остальных аргументов.
contains() {
  local needle=$1 item
  shift
  for item; do [[ $item == "$needle" ]] && return 0; done
  return 1
}

# Предложить пересборку после правки пульта ($PANEL). Сборка не удалась —
# вернуть пульт из копии $1. $2 — сообщение для коммита.
offer_rebuild() {
  local backup=$1 message=$2 answer=""
  read -rp "  Применить сейчас (rebuild)? [y/N] " answer || true
  if [[ $answer != [yYдД]* ]]; then
    dim "Применить позже: rebuild"
    return 1
  fi
  if rebuild -m "$message"; then
    return 0
  fi
  cp "$backup" "$PANEL"
  warn "Сборка не удалась — вернул пульт как было."
  return 1
}
