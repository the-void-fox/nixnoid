# votv — Voices of the Void. PROTON, DESYNC и YEETPATCH_URL приходят из
# ./default.nix. Всё лежит в ~/Games/VotV, другое место — VOTV_HOME.

root=${VOTV_HOME:-$HOME/Games/VotV}
game=$root/game
exe=$game/WindowsNoEditor/VotV.exe
prefix=$root/prefix
saves=$prefix/drive_c/users/steamuser/AppData/Local/VotV/Saved
yeet_dir=${XDG_DATA_HOME:-$HOME/.local/share}/yeetpatch

usage() {
  cat <<EOF

  votv              запустить игру
  votv update       обновить установленную версию до последней
  votv install      поставить любую версию из каталога
  votv yeetpatch    скачать свежий YeetPatch
  votv help         эта справка

  Игра:        $game
  Сохранения:  $saves

EOF
}

fail() {
  echo "votv: $*" >&2
  exit 1
}

fetch_yeetpatch() {
  echo "Скачиваю YeetPatch: $YEETPATCH_URL"
  mkdir -p "$yeet_dir"
  curl -fsSL "$YEETPATCH_URL" | tar -x -C "$yeet_dir"
}

# YeetPatch берёт папки только из строк в начале своего текста. Запускается
# его копия с вписанными путями, а скачанный оригинал остаётся как есть.
yeetpatch() {
  [[ -f $yeet_dir/YeetPatch.sh ]] || fetch_yeetpatch
  # desync из nixpkgs: иначе YeetPatch сам скачал бы его бинарь с github.
  ln -sfn "$DESYNC" "$yeet_dir/desync"

  local script=$yeet_dir/.YeetPatch-votv.sh
  sed -e "s|^INSTALL_DIR=\"\"|INSTALL_DIR=\"$game\"|" \
    -e "s|^SAVEGAME_DIR=\"\"|SAVEGAME_DIR=\"$saves\"|" \
    "$yeet_dir/YeetPatch.sh" >"$script"
  grep -q "^INSTALL_DIR=\"$game\"" "$script" ||
    fail "Новый YeetPatch задаёт папку установки иначе — votv надо поправить."
  bash "$script" "$@"
}

play() {
  [[ -f $exe ]] || fail "Игры нет в $game. Поставить: votv install"
  # GAMEID нужен для исправлений protonfixes; у этой игры своего нет.
  WINEPREFIX=$prefix GAMEID=umu-default PROTONPATH=$PROTON exec umu-run "$exe" "$@"
}

case ${1:-play} in
  play)
    shift || true
    play "$@"
    ;;
  update)
    shift
    # --pause — для ярлыка: окно терминала не закроется, пока не прочитаешь.
    pause=false
    if [[ ${1:-} == --pause ]]; then
      pause=true
      shift
    fi
    status=0
    yeetpatch update "$exe" || status=$?
    if $pause; then read -rp "Enter — закрыть окно " _ || true; fi
    exit "$status"
    ;;
  install)
    shift
    yeetpatch install "$@"
    ;;
  yeetpatch) fetch_yeetpatch ;;
  help | -h | --help) usage ;;
  *)
    usage
    exit 1
    ;;
esac
