# Шифрованная копия заголовка LUKS.
#
# Заголовок — первые мегабайты того же съёмного диска: мастер-ключ в обёртке и
# таблица слотов. Сбой моста при записи, неудачное выдёргивание или случайный
# dd по этим секторам — и данные не расшифрует никто, даже с паролем.
#
# Копия сама по себе секрет: с ней старый пароль работает и после смены
# пароля на диске. Поэтому шифруем.

dest=${1:-}
if [[ -z $dest ]]; then
  echo "Использование: luks-header-backup <каталог-назначения>" >&2
  echo "Например: luks-header-backup /run/media/$USER/USB" >&2
  exit 2
fi

# Раздел — по смонтированному корню, а не по имени: диск переносной, и на
# другой машине он легко окажется не /dev/sdb2.
root_src=$(realpath "/dev/mapper/$(basename "$(findmnt -no SOURCE /)")" 2>/dev/null || true)
part=$(sudo "$(command -v cryptsetup)" status "$root_src" 2>/dev/null \
  | grep -oP '^\s*device:\s*\K\S+' || true)

if [[ -z $part ]]; then
  echo "Не удалось определить LUKS-раздел автоматически." >&2
  echo "Посмотри 'lsblk' и выполни вручную:" >&2
  echo "  sudo cryptsetup luksHeaderBackup /dev/sdXN --header-backup-file hdr.img" >&2
  exit 1
fi

out="$dest/luks-header-$(date +%F).img.gpg"
tmp=$(mktemp)
trap 'shred -u "$tmp" 2>/dev/null || rm -f "$tmp"' EXIT

echo "Раздел: $part"
echo "Снимаю заголовок (нужен root) и шифрую в $out"
sudo "$(command -v cryptsetup)" luksHeaderBackup "$part" \
  --header-backup-file "$tmp" --batch-mode
sudo "$(command -v chown)" "$(id -u)" "$tmp"
gpg --symmetric --cipher-algo AES256 -o "$out" "$tmp"

echo "Готово: $out"
echo
echo "Храни ОТДЕЛЬНО от диска: с этой копией старый пароль работает даже"
echo "после смены пароля на диске. Восстановление:"
echo "  gpg -d $out > hdr.img"
echo "  sudo cryptsetup luksHeaderRestore $part --header-backup-file hdr.img"
