# bash-theme — тема оболочки. PANEL, AVAILABLE и CURRENT приходят из ./default.nix.

usage() {
  cat <<EOF

${c_info}  bash-theme — тема оболочки${c_off}

    bash-theme list        все темы
    bash-theme current     включённая
    bash-theme set ТЕМА    сменить

EOF
}

list() {
  echo
  info "🎨 Темы:"
  local theme
  for theme in "${AVAILABLE[@]}"; do
    if [[ $theme == "$CURRENT" ]]; then ok "  ● $theme  (включена)"; else dim "  ○ $theme"; fi
  done
  echo
}

set_theme() {
  local theme=$1 backup line
  if ! contains "$theme" "${AVAILABLE[@]}"; then
    list
    fail "Темы «$theme» нет."
  fi
  if [[ $theme == "$CURRENT" ]]; then
    warn "ℹ Тема «$theme» уже включена."
    return
  fi

  line='^([[:space:]]*custom\.shell\.theme = )"[^"]*";'
  grep -qE "$line" "$PANEL" || fail "В $PANEL нет строки custom.shell.theme = \"…\";"

  backup=$(mktemp)
  cp "$PANEL" "$backup"
  sed -E -i "s/$line/\\1\"$theme\";/" "$PANEL"
  ok "✓ Тема: $CURRENT → $theme"

  if offer_rebuild "$backup" "тема: $theme"; then
    ok "Новая тема — в новом окне терминала."
  fi
  rm -f "$backup"
}

case ${1:-help} in
  list | ls | l) list ;;
  current | c) info "🎨 Тема: $CURRENT" ;;
  set | s)
    (($# > 1)) || fail "Укажи тему: ${AVAILABLE[*]}"
    set_theme "$2"
    ;;
  help | -h | --help) usage ;;
  *)
    usage
    exit 1
    ;;
esac
