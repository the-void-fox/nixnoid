# Общее для всех тем. Тема подключается раньше и может переопределить
# __theme_not_found и __theme_wrong_layout — здесь они только запасные.

shopt -s histappend checkwinsize

# Клавиши русской раскладки → латинские на тех же местах.
declare -gA __latin_key=(
  [й]=q [ц]=w [у]=e [к]=r [е]=t [н]=y [г]=u [ш]=i [щ]=o [з]=p [х]='[' [ъ]=']'
  [ф]=a [ы]=s [в]=d [а]=f [п]=g [р]=h [о]=j [л]=k [д]=l [ж]=';' [э]="'"
  [я]=z [ч]=x [с]=c [м]=v [и]=b [т]=n [ь]=m [б]=',' [ю]='.' [ё]='`' [.]='/'
)

__latin_layout() {
  local text=$1 out="" i
  for ((i = 0; i < ${#text}; i++)); do
    out+=${__latin_key[${text:i:1}]-${text:i:1}}
  done
  printf '%s' "$out"
}

# Команда не нашлась. Набрана в русской раскладке («сдфгву» вместо «claude»)
# и на латинице такая есть — подсказать её. Только подсказать: само ничего
# не запускается, мало ли что получится из случайной строки.
command_not_found_handle() {
  local fixed
  if [[ $1 == *[а-яё]* ]]; then
    fixed=$(__latin_layout "$1")
    if type -t -- "$fixed" >/dev/null; then
      __theme_wrong_layout "$1" "$(__latin_layout "$*")"
      return 127
    fi
  fi
  __theme_not_found "$1"
  return 127
}

if ! declare -F __theme_not_found >/dev/null; then
  __theme_not_found() {
    printf '\n  ✗ Команда не найдена: %s\n    → nix-shell -p %s\n\n' "$1" "$1"
  }
fi

if ! declare -F __theme_wrong_layout >/dev/null; then
  __theme_wrong_layout() {
    printf '\n  ⌨  Раскладка не та. Может, имелось в виду: %s\n\n' "$2"
  }
fi
