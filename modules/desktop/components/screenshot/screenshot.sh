# screenshot [region|screen|annotate]
#   region   — область мышью; в файл и в буфер
#   screen   — весь экран
#   annotate — область, затем редактор satty: стрелки, текст, размытие

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date '+%Y-%m-%d %H-%M-%S').png" # как screenshot-path у niri

mode=${1:-region}
case $mode in
  region | annotate)
    # Esc или ПКМ отменяют выбор — slurp выходит с ошибкой.
    geometry=$(slurp -d) || exit 0
    [[ -n $geometry ]] || exit 0
    area=(-g "$geometry")
    ;;
  screen) area=() ;;
  *)
    echo "Использование: screenshot [region|screen|annotate]" >&2
    exit 2
    ;;
esac

if [[ $mode == annotate ]]; then
  # satty сам сохраняет файл и кладёт снимок в буфер.
  grim "${area[@]}" - | satty --filename - \
    --output-filename "$file" \
    --early-exit \
    --copy-command wl-copy
else
  grim "${area[@]}" "$file"
  wl-copy <"$file"
  notify-send -i "$file" "Снимок сохранён" "$file"
fi
