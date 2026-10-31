# desktop-env — какие сессии видны в окне входа.
# PANEL, AVAILABLE и CURRENT приходят из ./default.nix.

usage() {
  cat <<EOF

${c_info}  desktop-env — сессии в окне входа${c_off}

    desktop-env list             все сессии
    desktop-env current          включённые
    desktop-env set СЕССИЯ…      заменить список целиком
    desktop-env add СЕССИЯ       добавить
    desktop-env remove СЕССИЯ    убрать

EOF
}

list() {
  echo
  info "Сессии:"
  local s
  for s in "${AVAILABLE[@]}"; do
    if contains "$s" "${CURRENT[@]}"; then ok "  ● $s  (включена)"; else dim "  ○ $s"; fi
  done
  echo
}

check() {
  contains "$1" "${AVAILABLE[@]}" && return
  list
  fail "Сессии «$1» нет."
}

# Переписать список в пульте и предложить пересборку. Понимает и строку
# `[ "a" ]`, и многострочный список, в который его разворачивает nixfmt.
apply() {
  local backup tmp
  backup=$(mktemp)
  tmp=$(mktemp)
  cp "$PANEL" "$backup"

  if ! SESSIONS="$*" awk '
    /^[[:space:]]*custom\.desktop\.sessions = \[/ {
      indent = substr($0, 1, match($0, /[^[:space:]]/) - 1)
      n = split(ENVIRON["SESSIONS"], s, " ")
      if (n == 1) {
        print indent "custom.desktop.sessions = [ \"" s[1] "\" ];"
      } else {
        print indent "custom.desktop.sessions = ["
        for (i = 1; i <= n; i++) print indent "  \"" s[i] "\""
        print indent "];"
      }
      skip = $0 !~ /\];/
      found++
      next
    }
    skip { if ($0 ~ /\];/) skip = 0; next }
    { print }
    END { exit (found != 1) }
  ' "$PANEL" >"$tmp"; then
    rm -f "$tmp" "$backup"
    fail "В $PANEL нет единственной строки custom.desktop.sessions = [ … ];"
  fi

  cat "$tmp" >"$PANEL"
  rm -f "$tmp"
  ok "✓ Сессии: $*"

  if offer_rebuild "$backup" "сессии: $*"; then
    ok "Готово: новые сессии — в окне входа после выхода из текущей."
  fi
  rm -f "$backup"
}

case ${1:-help} in
  list | ls | l) list ;;
  current | c) printf '%s\n' "${CURRENT[@]}" ;;
  set | s)
    shift
    (($#)) || fail "Укажи хотя бы одну сессию."
    for session; do check "$session"; done
    apply "$@"
    ;;
  add | a)
    (($# > 1)) || fail "Укажи сессию."
    check "$2"
    if contains "$2" "${CURRENT[@]}"; then
      warn "ℹ $2 уже включена."
      exit 0
    fi
    apply "${CURRENT[@]}" "$2"
    ;;
  remove | rm | r)
    (($# > 1)) || fail "Укажи сессию."
    contains "$2" "${CURRENT[@]}" || fail "$2 и так не включена."
    rest=()
    for session in "${CURRENT[@]}"; do
      [[ $session == "$2" ]] || rest+=("$session")
    done
    ((${#rest[@]})) || fail "Последнюю сессию убрать нельзя — войти будет не во что."
    apply "${rest[@]}"
    ;;
  help | -h | --help) usage ;;
  *)
    usage
    exit 1
    ;;
esac
