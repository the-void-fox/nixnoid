# niri — бесконечная лента колонок. Панель и лаунчер — noctalia.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.custom.desktop) cursor monitors;

  outputs = lib.concatMapStrings (m: ''
    output "${m.name}" {
        mode "${m.mode}"
        scale ${m.scale}
        position x=${toString m.x} y=${toString m.y}
    }
  '') (lib.attrValues monitors);
in
{
  config = lib.mkIf (lib.elem "niri" config.custom.desktop.sessions) {
    programs.niri.enable = true;
    custom.desktop.noctalia.enable = true;

    environment.systemPackages = [ pkgs.xwayland-satellite ];

    # Агент polkit — только в niri: у hyprstack свой, и вдвоём они конфликтуют.
    # Условие нужно, когда в списке сессий обе: target поднимается в каждой.
    systemd.user.services.hyprpolkitagent = {
      description = "Hyprland Polkit authentication agent";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
      serviceConfig = {
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # force: файлы, оставшиеся от прежних запусков, home-manager иначе не тронет.
    hm.xdg.configFile = lib.mapAttrs (_: file: file // { force = true; }) {
      "niri/config.kdl".source = ./config.kdl;
      "niri/binds.kdl".source = ./binds.kdl;
      "niri/outputs.kdl".text = outputs;
      "niri/cursor.kdl".text = ''
        cursor {
            xcursor-theme "${cursor.name}"
            xcursor-size ${toString cursor.size}
        }
      '';
    };
  };
}
