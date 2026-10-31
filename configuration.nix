# ╭──────────────────────────────────────────────────────────────────────────╮
# │  Пульт: то, что выбирается вкусом. Как оно устроено — в modules/.        │
# ╰──────────────────────────────────────────────────────────────────────────╯
# Строки с сессиями и темой переписывают `desktop-env` и `bash-theme`.
{
  imports = [
    ./hardware-configuration.nix
    ./modules
  ];

  networking.hostName = "nixos";
  custom.user = "voidfox";

  # Сессии в окне входа. Каждая приносит только своё: noctalia, например,
  # ставится лишь вместе с niri, mango или driftwm.
  custom.desktop.sessions = [ "hyprstack" ];

  custom.shell.theme = "nixi";

  # Мониторы — сразу для всех композиторов. Имя — коннектор, его покажут
  # `hyprctl monitors` или `niri msg outputs`.
  custom.desktop.monitors = {
    DP-3.mode = "2560x1440@143.999";
    HDMI-A-1 = {
      mode = "1920x1080@60";
      position = "-1920x320";
    };
  };

  # Автозапуск: монитор → стол на нём → команда. Окна — развёрнутыми.
  # custom.desktop.autostart = {
  #   DP-3 = {
  #     "1" = "helium";
  #     "10" = "obsidian";
  #   };
  #   HDMI-A-1 = {
  #     "1" = "flatpak run dev.vencord.Vesktop";
  #     "2" = "ayugram-desktop";
  #   };
  # };

  # ── Подсистемы ────────────────────────────────────────────────────────────
  # Всё, что можно выключить, — здесь. Выключить: `= false;`. Строку убрать —
  # останется значение по умолчанию, указано в конце каждой строки. Подробно —
  # в описании опции в модуле, путь в скобках.

  # Сеть (system/networking.nix).
  custom.network.dnscrypt.enable = true; # DNS только шифрованно. По умолч. true
  custom.network.tailscale.enable = true; # По умолч. true
  custom.network.tailscale.exitNode = true; # быть выходным узлом. По умолч. true

  # VPN и обход блокировок (system/vpn.nix). Всё по умолчанию false, туннель
  # одновременно — один. Что включено и что поднято — команда `vpn`.
  custom.vpn.amnezia.enable = false; # AmneziaVPN, туннель с окном
  custom.vpn.wireguard.enable = false; # WireGuard, импорт через nmcli
  custom.vpn.throne.enable = false; # VLESS/Trojan/…: прокси 127.0.0.1:2080
  custom.vpn.throne.tun = false; # …или туннель на всю систему
  custom.vpn.byedpi.enable = false; # обход DPI без сервера: SOCKS 127.0.0.1:1080
  custom.vpn.tor.enable = false; # Tor: SOCKS 127.0.0.1:9050
  # custom.vpn.tor.bridges = [ "obfs4 …" ]; # если Tor напрямую не пускают

  # Защита (security/, system/boot.nix).
  custom.secureBoot.enable = true; # без ключей в /etc/secureboot — false. По умолч. true
  custom.security.usbguard.enable = true; # новые USB — по кнопке. По умолч. true
  custom.hardening.signedModulesOnly = false; # на ядре 7.3 не грузится. По умолч. false

  # Группы программ (apps/). По умолчанию все true. Утилиты (tools.nix) и
  # файлы (files.nix) — основа, не выключаются; git остаётся и без dev.
  custom.apps.dev.enable = true; # Rust, редакторы, Redot, Podman
  custom.apps.games.enable = true; # Steam, Wine, Proton, лаунчеры
  custom.apps.votv.enable = true; # Voices of the Void, нужны games
  custom.apps.media.enable = true; # Krita, GIMP, Kdenlive, OBS
  custom.apps.social.enable = true; # мессенджеры, KDE Connect, RustDesk
  custom.apps.ai.enable = true; # ollama на ROCm, koboldcpp

  # Свои копии входов флейка: `rebuild --local hyprstack` соберёт систему
  # из этого каталога вместо github.
  custom.rebuild.localInputs = {
    hyprstack = "/home/voidfox/Project/Linux/hyprstack-shell";
    void-connect = "/home/voidfox/Project/Rust/VoidConnect";
    rust-rim = "/home/voidfox/Project/Rust/rust-rim";
  };

  # Отметка релиза, с которого ставилась система, а не её версия. Не менять:
  # от неё зависят форматы данных, которые службы уже записали на диск.
  system.stateVersion = "25.05";
}
