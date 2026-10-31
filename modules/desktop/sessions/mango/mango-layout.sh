# mango-layout [status|watch|next|menu] — раскладка окон mango для панели
# noctalia: своего виджета для неё там нет, кнопка собрана из CustomButton.
#
# mango называет раскладки короткими символами, как dwm. Соответствие снято
# перебором на живой системе.

names=(
  tile scroller monocle grid deck center_tile right_tile
  vertical_tile vertical_scroller vertical_grid vertical_deck
)

label() {
  case $1 in
    T) echo "Tile" ;;
    S) echo "Scroller" ;;
    M) echo "Monocle" ;;
    G) echo "Grid" ;;
    K) echo "Deck" ;;
    CT) echo "Center" ;;
    RT) echo "Right" ;;
    VT) echo "V-Tile" ;;
    VS) echo "V-Scroll" ;;
    VG) echo "V-Grid" ;;
    VK) echo "V-Deck" ;;
    *) echo "$1" ;;
  esac
}

# Символ раскладки АКТИВНОГО монитора — одним вызовом: без флагов mmsg
# печатает полный срез, где есть и selmon, и layout каждого выхода.
current() {
  mmsg -g 2>/dev/null | awk '
    $2 == "selmon" && $3 == "1" { sel = $1 }
    $2 == "layout"              { lay[$1] = $3 }
    END { if (sel != "" && lay[sel] != "") print lay[sel] }
  ' || true
}

last=""
emit() {
  local now
  now=$(label "$(current)")
  if [[ $now != "$last" ]]; then
    echo "$now"
    last=$now
  fi
}

case ${1:-status} in
  status) label "$(current)" ;;
  watch)
    # Этот режим не должен завершаться НИКОГДА: noctalia перезапускает команду
    # сразу после выхода, и вне mango это был бы бесконечный цикл перезапусков
    # (25 штук за полминуты в журнале и тормоза всего бара). Поэтому без mango
    # тихо ждём её, а ушла mango — ждём снова.
    while :; do
      if [[ -z $(current) ]]; then
        sleep 5
        continue
      fi
      emit
      # mmsg -w -l шлёт строку на КАЖДЫЙ монитор — это лишь сигнал «что-то
      # поменялось», а значение берётся у активного.
      mmsg -w -l 2>/dev/null | while read -r _; do emit; done || true
      sleep 2
    done
    ;;
  next) mmsg -s -d switch_layout >/dev/null 2>&1 ;;
  menu)
    choice=$(printf '%s\n' "${names[@]}" | rofi -dmenu -i -p "Раскладка окон" || true)
    if [[ -n $choice ]]; then
      mmsg -s -d "setlayout,$choice" >/dev/null 2>&1
    fi
    ;;
  *)
    echo "Использование: mango-layout [status|watch|next|menu]" >&2
    exit 2
    ;;
esac
