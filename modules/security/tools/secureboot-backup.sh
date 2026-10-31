# Шифрованная копия ключей Secure Boot. Без неё смерть SSD — это потеря
# ключей, которыми подписан загрузчик.

dest=${1:-}
if [[ -z $dest ]]; then
  echo "Использование: secureboot-backup <каталог-назначения>" >&2
  echo "Например: secureboot-backup /run/media/$USER/USB" >&2
  exit 2
fi

out="$dest/secureboot-$(date +%F).tar.gz.gpg"
echo "Читаю /etc/secureboot (нужен root) и шифрую в $out"
sudo "$(command -v tar)" -czf - -C /etc secureboot \
  | gpg --symmetric --cipher-algo AES256 -o "$out"
echo "Готово: $out"
echo "Проверь, что файл читается, и храни его отдельно от этого ПК."
