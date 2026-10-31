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
