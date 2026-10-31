# nixnoid — a setup for mildly paranoid people

> Personal NixOS flake: a portable install on a removable SSD with LUKS,
> Secure Boot (lanzaboote), a hardened kernel, USBGuard, DNS over
> dnscrypt-proxy and four Wayland sessions. Comments and docs are in Russian.

Переносная NixOS на съёмном SSD: LUKS, Secure Boot (lanzaboote), укреплённое
ядро, USBGuard, DNS только через dnscrypt-proxy.

## Где что

```
configuration.nix   пульт: сессии, тема, мониторы, локальные копии входов
flake.nix           входы и выходы флейка (система, nix fmt, devShell rust)
pkgs/               свои пакеты + оверлей, который кладёт их в pkgs.*
modules/
  system/           загрузка, nix, сеть, пользователь, rebuild, diag
  hardware/         переносимость, видео, диск, периферия, звук
  security/         ядро, sudo/polkit/PAM, USBGuard, резервные копии ключей
  desktop/          окно входа, тема, приложения по умолчанию, мониторы
    components/     noctalia, портал wlroots, скриншоты — по запросу сессий
    sessions/       hyprstack, niri, mango, driftwm — каждая со своим конфигом
  apps/             программы по назначению: dev, games, media, files, …
  shell/            bash: темы, алиасы, подсказка раскладки
```

Сессия приносит только своё. noctalia, портал wlroots и `screenshot` ставятся,
лишь когда их включает niri, mango или driftwm.

Новая программа — в файл `modules/apps/` по назначению: консольная утилита —
в `environment.systemPackages`, приложение — в `hm.home.packages`, flatpak — в
`services.flatpak.packages` того же файла.

## Команды

| Команда | Что делает |
|---|---|
| `rebuild` | собрать и применить, затем коммит с кодовым именем |
| `rebuild test` / `build` / `boot` | без коммита / только собрать / со следующей загрузки |
| `rebuild -m "текст"` | дописать текст к сообщению коммита |
| `update` (`rebuild -u`) | обновить входы флейка и пересобрать |
| `rebuild -l hyprstack` | собрать с локальной копией входа (`custom.rebuild.localInputs`) |
| `rebuild -H` | одна тяжёлая сборка на все ядра |
| `desktop-env list` / `add` / `remove` / `set` | сессии в окне входа |
| `bash-theme list` / `set` | тема оболочки |
| `diag > ~/diag.txt` | состояние системы одним текстом |
| `secureboot-backup <каталог>` | шифрованная копия ключей Secure Boot |
| `luks-header-backup <каталог>` | шифрованная копия заголовка LUKS |
| `nix fmt` | привести репозиторий к nixfmt |
| `nix develop /etc/nixos#rust` | окружение для Rust с графикой |
| `votv` / `votv update` | Voices of the Void через Proton; обновления — официальным YeetPatch |

`rebuild` запускается без sudo: собирает от пользователя, а root нужен только
для активации — пароль спрашивается сразу и держится, пока идёт сборка.

## Взять себе

Это личный конфиг, а не дистрибутив: удобнее брать из него модули по одному.
Если собирать целиком на своей машине, сначала поменяй то, без чего она не
загрузится или не пустит тебя:

1. `hardware-configuration.nix` — свой (`nixos-generate-config`). Имя
   LUKS-устройства есть ещё и в `modules/hardware/storage.nix`.
2. В `configuration.nix` — свои `custom.user`, `networking.hostName`, мониторы
   и `custom.rebuild.localInputs` (это пути к моим копиям проектов).
3. Пароля в конфиге нет, а `users.mutableUsers = false`: до первого `switch`
   создай `/persist/secrets/<пользователь>-password`
   (`mkpasswd -m yescrypt`), иначе войти будет нельзя.
4. Secure Boot: lanzaboote ждёт ключи в `/etc/secureboot`
   (`boot.lanzaboote.pkiBundle`). Как их создать и записать в прошивку —
   в [документации lanzaboote](https://nix-community.github.io/lanzaboote/).
5. USBGuard пускает то, что воткнуто до загрузки, и устройства из
   `modules/security/usbguard/allowed.rules`. Остальное блокируется до нажатия
   «Разрешить» в уведомлении — впиши туда свои.
6. Tailscale включён выходным узлом. Не нужен — убери из
   `modules/system/networking.nix`.

## Лицензия

GPL-3.0 — текст в [LICENSE](LICENSE).
