# driftwm — экспериментальный композитор на Rust/Smithay. Вместо тайлинга —
# бесконечный холст: окна лежат в родном размере, а экран — подвижное и
# масштабируемое окно просмотра. Рассчитан прежде всего на тачпад.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # В TOML — в конец файла: массив таблиц там ничему не мешает.
  # Частота у driftwm только целая: "143.999" он отвергает.
  outputs = lib.concatMapStrings (m: ''

    [[outputs]]
    name = "${m.name}"
    mode = "${toString m.width}x${toString m.height}@${toString m.hz}"
    scale = ${m.scale}
    position = [${toString m.x}, ${toString m.y}]
  '') (lib.attrValues config.custom.desktop.monitors);
in
{
  # Модуль лишь объявляет programs.driftwm.*, включается он ниже.
  imports = [ inputs.driftwm.nixosModules.default ];

  config = lib.mkIf (lib.elem "driftwm" config.custom.desktop.sessions) {
    # Сам модуль даёт xwayland-satellite, сессию в окне входа, юниты systemd,
    # polkit и gnome-keyring. Порталы — нет: только пожелания в своём
    # driftwm-portals.conf, а NixOS собирает их из xdg.portal.config.
    programs.driftwm.enable = true;

    custom.desktop = {
      noctalia.enable = true;
      screenshot.enable = true;
      wlrPortal.desktops = [ "driftwm" ];
    };

    environment.systemPackages = with pkgs; [
      grim # Print в config.toml
      slurp
      playerctl # медиаклавиши: так их привязывает сам driftwm
    ];

    hm.xdg.configFile."driftwm/config.toml" = {
      force = true;
      text = builtins.readFile ./config.toml + outputs;
    };
  };
}
