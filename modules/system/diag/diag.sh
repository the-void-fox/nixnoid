# Отчёт должен читаться чужими глазами: одинаковые заголовки, и пустота
# нигде не остаётся молчаливой — либо данные, либо «не удалось».

h() {
  local rule
  printf -v rule '%*s' $((60 - ${#1})) ''
  printf '\n══ %s %s\n' "$1" "${rule// /═}"
}

try() { "$@" 2>/dev/null || echo "  (не удалось: $*)"; }

# Сдвинуть вывод вправо; $1 — свой префикс вместо двух пробелов.
indent() { sed "s/^/${1:-  }/"; }

echo "ДИАГНОСТИКА СИСТЕМЫ — $(date '+%Y-%m-%d %H:%M')"

h "Система"
generation=$(readlink /run/current-system)
echo "  NixOS:     $(nixos-version 2>/dev/null || echo '?')"
echo "  Ядро:      $(uname -r)"
echo "  Машина:    $(uname -n)"
echo "  Аптайм:    $(uptime -p 2>/dev/null || uptime)"
echo "  Поколение: ${generation#/nix/store/}"

h "Железо"
echo "  Процессор: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //')"
free -h | head -2 | indent
echo
df -h / /boot 2>/dev/null | indent

h "Системный диск"
root_src=$(findmnt -no SOURCE / 2>/dev/null)
# Корень лежит на LUKS, тот — на разделе, раздел — на диске. lsblk -s идёт
# по этой цепочке снизу вверх; последняя строка с типом disk и есть железка.
root_dev=$(lsblk -s -rno NAME,TYPE "$root_src" 2>/dev/null | awk '$2 == "disk" { print $1 }' | tail -1)
[[ -n $root_dev ]] || root_dev=$(basename "$root_src")
queue=/sys/block/$root_dev/queue
echo "  Корень на:  $root_src  (диск $root_dev)"
df -h / | awk 'NR == 2 { printf "  Занято:     %s из %s (%s)\n", $3, $2, $5 }'

# Для переносной системы это первое, что стоит проверить: на USB 2 диск
# работает раз в сорок медленнее, а снаружи это выглядит как «просто тормозит».
dev_path=$(readlink -f "/sys/block/$root_dev" 2>/dev/null)
if [[ $dev_path == *usb* ]]; then
  port=$(grep -oE 'usb[0-9]+/[0-9]+-[0-9.]+' <<<"$dev_path" | tail -1)
  port=${port##*/}
  speed=$(cat "/sys/bus/usb/devices/$port/speed" 2>/dev/null)
  printf '  Подключение: USB, порт %s, %s Мбит/с — ' "$port" "$speed"
  case $speed in
    10000 | 5000) echo "USB 3, нормально" ;;
    480) echo "USB 2, В СОРОК РАЗ МЕДЛЕННЕЕ, ЧЕМ НАДО" ;;
    *) echo "неизвестно" ;;
  esac
else
  echo "  Подключение: внутреннее"
fi

# Без TRIM контроллер SSD не знает о свободных блоках и со временем
# деградирует. Часть USB-мостов его не пропускает.
if [[ $(cat "$queue/discard_max_bytes" 2>/dev/null) =~ ^[1-9] ]]; then
  echo "  TRIM:        работает"
else
  echo "  TRIM:        НЕ РАБОТАЕТ (диск не чистится)"
fi
echo "  Упреждающее чтение: $(cat "$queue/read_ahead_kb" 2>/dev/null) КБ (норма 128-256)"
echo "  Планировщик: $(cat "$queue/scheduler" 2>/dev/null)"
echo "  Давление ввода-вывода: $(head -1 /proc/pressure/io 2>/dev/null | cut -d' ' -f2)"

h "Видео"
try lspci -nn | grep -iE 'vga|3d|display' | indent
echo "  Сессия:      ${XDG_SESSION_TYPE:-?} / ${XDG_CURRENT_DESKTOP:-?}"
echo "  Драйвер VA:  ${LIBVA_DRIVER_NAME:-не задан}"
echo "  Wayland для Electron: ${NIXOS_OZONE_WL:-не задан}"
echo "  — аппаратное декодирование видео:"
vainfo 2>/dev/null | grep -E 'vainfo: Driver|VAProfileH264High|VAProfileAV1' | indent "    " \
  || echo "    не работает — видео декодирует процессор"

h "Звук"
echo "  pipewire wireplumber: $(systemctl --user is-active pipewire wireplumber 2>/dev/null | tr '\n' ' ')"
try wpctl status | sed -n '/Sinks:/,/Sources:/p' | head -8 | indent

h "Сеть"
try ip -brief address | indent
echo "  Маршрут по умолчанию:"
try ip route show default | indent "    "
echo "  Серверы имён:"
try resolvectl status | grep -E 'Current DNS|DNS Servers' | head -4 | indent "    "

h "Сбойные службы"
failed=$(systemctl --failed --no-legend --no-pager 2>/dev/null)
if [[ -n $failed ]]; then indent <<<"$failed"; else echo "  нет — это хорошо"; fi
failed=$(systemctl --user --failed --no-legend --no-pager 2>/dev/null)
if [[ -n $failed ]]; then indent "  (пользователь) " <<<"$failed"; fi

h "Ошибки с последней загрузки"
errors=$(journalctl -p err -b --no-pager -n 25 2>/dev/null | grep -v '^-- ' | tail -20)
if [[ -n $errors ]]; then indent <<<"$errors"; else echo "  нет"; fi

echo
echo "── Конец. Сохранить в файл:  diag > ~/diag.txt"
