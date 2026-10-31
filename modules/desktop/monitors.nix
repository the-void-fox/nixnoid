# Мониторы — одна таблица на все композиторы. Каждая сессия переводит её на
# свой язык (KDL, Lua, conf, TOML) и со своими причудами: кому-то нужна точная
# частота, кому-то целая, а кто-то не терпит отрицательных координат.
{ lib, ... }:

let
  inherit (lib) mkOption types;

  monitor = types.submodule (
    { name, config, ... }:
    let
      mode = builtins.match "([0-9]+)x([0-9]+)@([0-9.]+)" config.mode;
      position = builtins.match "(-?[0-9]+)x(-?[0-9]+)" config.position;
      at = list: i: builtins.fromJSON (builtins.elemAt list i);
    in
    {
      options = {
        mode = mkOption {
          type = types.strMatching "[0-9]+x[0-9]+@[0-9]+(\\.[0-9]+)?";
          example = "2560x1440@143.999";
          description = ''
            Режим «ШxВ@Гц». Частоту — ровно как её объявляет монитор: niri и
            hyprland берут её дословно, а кому нужны целые герцы, тот округлит.
          '';
        };
        position = mkOption {
          type = types.strMatching "-?[0-9]+x-?[0-9]+";
          default = "0x0";
          description = "Левый верхний угол в общей раскладке, «XxY». Бывает отрицательным.";
        };
        scale = mkOption {
          type = types.strMatching "[0-9]+\\.[0-9]+";
          default = "1.0";
          description = "Масштаб строкой, чтобы его можно было вписать в любой формат как есть.";
        };

        # Разобранные поля — для тех, кому нужна не строка.
        name = mkOption {
          readOnly = true;
          default = name;
        };
        width = mkOption {
          readOnly = true;
          default = at mode 0;
        };
        height = mkOption {
          readOnly = true;
          default = at mode 1;
        };
        refresh = mkOption {
          readOnly = true;
          default = builtins.elemAt mode 2;
          description = "Частота строкой, как в mode.";
        };
        hz = mkOption {
          readOnly = true;
          default = builtins.floor (at mode 2 + 0.5);
          description = "Частота, округлённая до целых герц.";
        };
        x = mkOption {
          readOnly = true;
          default = at position 0;
        };
        y = mkOption {
          readOnly = true;
          default = at position 1;
        };
      };
    }
  );
in
{
  options.custom.desktop.monitors = mkOption {
    type = types.attrsOf monitor;
    default = { };
    description = "Мониторы по именам коннекторов (DP-3, HDMI-A-1…).";
  };
}
