# FLAKE, HOST и LOCAL_INPUTS приходят из ./default.nix.
#
# Всё, кроме активации, идёт от пользователя. Пока сборка шла целиком через
# `sudo nixos-rebuild`, root при вычислении флейка переписывал .git/index, и
# после этого обычный `git add` падал с «insufficient permission».

usage() {
  cat <<EOF

${c_info}  rebuild [switch|boot|test|build] [параметры]${c_off}

    -m, --message ТЕКСТ  дописать к сообщению коммита
    -u, --update         сначала обновить входы флейка (flake.lock)
    -l, --local ВХОД     собрать с локальной копией входа; можно повторять
    -H, --heavy          одна сборка на все ядра — для одного тяжёлого пакета
    -h, --help           эта справка

${c_dim}  Коммит появляется только после удачных switch и boot.
  Локальные копии (custom.rebuild.localInputs): ${!LOCAL_INPUTS[*]}${c_off}

EOF
}

((EUID != 0)) || fail "Запускай без sudo: root нужен только для активации, пароль спрошу сам."

mode=switch
message=""
update=false
heavy=false
locals=()

while (($#)); do
  case $1 in
    switch | boot | test | build) mode=$1 ;;
    -m | --message)
      (($# > 1)) || fail "После $1 нужен текст."
      message=$2
      shift
      ;;
    -u | --update) update=true ;;
    -l | --local)
      (($# > 1)) || fail "После $1 нужно имя входа: ${!LOCAL_INPUTS[*]}"
      locals+=("$2")
      shift
      ;;
    -H | --heavy) heavy=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage
      fail "Неизвестный аргумент: $1"
      ;;
  esac
  shift
done

cd "$FLAKE"
args=(--flake ".#$HOST" --diff)

for name in "${locals[@]}"; do
  path=${LOCAL_INPUTS[$name]:-}
  [[ -n $path ]] || fail "Локальной копии «$name» нет. Есть: ${!LOCAL_INPUTS[*]}"
  args+=(--override-input "$name" "git+file://$path")
  dim "🧪 $name ← $path"
done

if $heavy; then
  cores=$(nproc) # не константа: диск переносной, железо под ним разное
  args+=(--cores "$cores" --max-jobs 1)
  warn "⚡ --heavy: одна сборка на $cores ядер"
fi

if $update; then
  info "🔄 Обновляю входы флейка"
  nix flake update --flake .
fi

# Флейк видит только то, что знает git: без этого новый файл для сборки
# не существует, и ошибка указывает куда-то в /nix/store.
dim "📦 git add -A"
git add -A || fail "git add не сработал — сборку не начинаю.
    Если часть .git принадлежит root, это лечится один раз:
    sudo chown -R $(id -un):$(id -gn) $(realpath "$FLAKE")/.git"

if [[ $mode != build ]]; then
  args+=(--sudo)
  # Пароль — сейчас, пока ты у экрана, а не в конце долгой сборки.
  sudo -v || fail "Без sudo систему не применить."
  while sleep 60; do sudo -n -v 2>/dev/null || exit; done &
  keepalive=$!
  trap 'kill "$keepalive" 2>/dev/null' EXIT
fi

info "🔨 nixos-rebuild $mode"
echo
if ! nixos-rebuild "$mode" "${args[@]}"; then
  echo
  fail "Сборка упала, коммита нет. Изменения остались в индексе git."
fi
echo

if [[ $mode == test || $mode == build ]]; then
  ok "✓ $mode прошёл. Для $mode коммит не создаётся."
  exit 0
fi

if git diff --cached --quiet; then
  warn "ℹ Конфиг не менялся — коммитить нечего."
  exit 0
fi

adjectives=(
  "Лазурный" "Хрустальный" "Полночный" "Янтарный" "Шёлковый"
  "Изумрудный" "Бархатный" "Туманный" "Снежный" "Закатный"
  "Лунный" "Огненный" "Стальной" "Сиреневый" "Грозовой"
  "Медный" "Звёздный" "Малиновый" "Северный" "Багряный"
  "Перламутровый" "Дымчатый" "Коралловый" "Сосновый" "Песчаный"
  "Озёрный" "Вечерний" "Утренний" "Морозный" "Терракотовый"
  "Бирюзовый" "Кленовый" "Васильковый" "Золотой" "Сапфировый"
)
nouns=(
  "Барсук" "Сокол" "Лис" "Енот" "Олень"
  "Тигр" "Ворон" "Кит" "Дельфин" "Сова"
  "Рысь" "Журавль" "Выдра" "Ёж" "Зубр"
  "Феникс" "Дракон" "Грифон" "Единорог" "Пегас"
  "Манул" "Капибара" "Леопард" "Хорёк" "Ягуар"
  "Гепард" "Аксолотль" "Лемур" "Альбатрос" "Фламинго"
  "Скат" "Краб" "Богомол" "Светлячок" "Стрекоза"
)

today=$(date +%F)
count=$(git log --since="$today 00:00" --format=%s | grep -c "^$today #" || true)
codename="${adjectives[RANDOM % ${#adjectives[@]}]} ${nouns[RANDOM % ${#nouns[@]}]}"

notes=()
if $update; then notes+=("обновление"); fi
if ((${#locals[@]})); then notes+=("локально: ${locals[*]}"); fi
if [[ -n $message ]]; then notes+=("$message"); fi

note=""
for part in "${notes[@]}"; do note+="${note:+; }$part"; done
subject="$today #$((count + 1)) — $codename${note:+: $note}"

git commit -q -m "$subject"
echo
ok "✓ Коммит: ${c_warn}$subject"
echo
