# nixnoid — a setup for mildly paranoid people

> Personal NixOS flake: a portable install on a removable SSD with LUKS,
> Secure Boot (lanzaboote), a hardened kernel, USBGuard, DNS over
> dnscrypt-proxy and four Wayland sessions. Comments and docs are in Russian.

Переносная NixOS на съёмном SSD: LUKS, Secure Boot (lanzaboote), укреплённое
ядро, USBGuard, DNS только через dnscrypt-proxy.

## Где что

```
configuration.nix   пульт: сессии, тема, мониторы, переключатели подсистем
flake.nix           входы и выходы флейка (система, nix fmt, devShell rust)
pkgs/               свои пакеты + оверлей, который кладёт их в pkgs.*
modules/
  system/           загрузка, nix, сеть, VPN, пользователь, rebuild, diag
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

## Что выключается

Всё, без чего машина обходится, выключается одной строкой в
`configuration.nix`, в блоке «Подсистемы»: `= false;`. Если строку
удалить, действует значение по умолчанию, оно указано в комментарии рядом.

| Опция | По умолч. | Что даёт |
|---|---|---|
| `custom.network.dnscrypt.enable` | `true` | DNS только шифрованно, через dnscrypt-proxy |
| `custom.network.tailscale.enable` | `true` | Tailscale |
| `custom.network.tailscale.exitNode` | `true` | эта машина — выходной узел тайлнета |
| `custom.secureBoot.enable` | `true` | lanzaboote; `false` — обычный systemd-boot |
| `custom.security.usbguard.enable` | `true` | новые USB-устройства — только по кнопке |
| `custom.hardening.signedModulesOnly` | `false` | только подписанные модули ядра |
| `custom.apps.<группа>.enable` | `true` | `dev`, `games`, `votv`, `media`, `social`, `ai` |
| `custom.vpn.*` | `false` | VPN и обход блокировок, ниже |

### VPN

Модуль `modules/system/vpn.nix`. Всё выключено, включается по одному
способу на строку:

| Опция | Род | Как пользоваться |
|---|---|---|
| `custom.vpn.amnezia.enable` | туннель | AmneziaVPN, окно; ключ от своего сервера |
| `custom.vpn.wireguard.enable` | туннель | `nmcli connection import type wireguard file wg0.conf` |
| `custom.vpn.throne.enable` | прокси | Throne, подписки VLESS/Trojan/…; порт `127.0.0.1:2080` |
| `custom.vpn.throne.tun` | туннель | Throne на всю систему, а не прокси |
| `custom.vpn.byedpi.enable` | прокси | обход DPI без сервера, SOCKS5 `127.0.0.1:1080` |
| `custom.vpn.tor.enable` | прокси | Tor, SOCKS5 `127.0.0.1:9050`; мосты — `custom.vpn.tor.bridges` |

Туннель забирает весь трафик, и поднят должен быть один: два дерутся за
маршрут, и сеть пропадает. Прокси только слушают порт, работают сколько
угодно одновременно и вместе с туннелем. Что поднято сейчас — команда `vpn`.

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
| `vpn` | маршрут, туннели, VPN-службы и прокси на 127.0.0.1 |
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
   (`boot.lanzaboote.pkiBundle`). Ключей нет — ставь с
   `custom.secureBoot.enable = false`, а включи, когда создашь и запишешь их
   в прошивку ([документация lanzaboote](https://nix-community.github.io/lanzaboote/)).
5. USBGuard пускает то, что воткнуто до загрузки, и устройства из
   `modules/security/usbguard/allowed.rules`. Остальное блокируется до нажатия
   «Разрешить» в уведомлении — впиши туда свои.
6. Tailscale включён выходным узлом. Не нужен —
   `custom.network.tailscale.enable = false`, только клиент —
   `custom.network.tailscale.exitNode = false`.

## Лицензия

GPL-3.0 — текст в [LICENSE](LICENSE).
