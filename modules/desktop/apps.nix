# Терминал, браузер и файловый менеджер — в одном месте. Отсюда их берут
# переменные сеанса, xdg-terminal-exec, ассоциации файлов, hyprstack, noctalia
# и Nautilus. Исключение — бинд терминала в готовых конфигах niri, mango и
# driftwm: там он назван по имени.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.apps;

  app =
    description: default:
    lib.mkOption {
      inherit description default;
      type = lib.types.submodule (
        { config, ... }:
        {
          options = {
            package = lib.mkOption { type = lib.types.package; };
            desktopId = lib.mkOption {
              type = lib.types.str;
              description = "Имя .desktop-файла без расширения.";
            };
            command = lib.mkOption {
              type = lib.types.str;
              default = config.package.meta.mainProgram or (lib.getName config.package);
              defaultText = "главная программа пакета";
            };
          };
        }
      );
    };

  roles = [
    "terminal"
    "browser"
    "fileManager"
  ];

  desktop = role: "${cfg.${role}.desktopId}.desktop";
in
{
  options.custom.apps = {
    terminal = app "Терминал." {
      package = pkgs.ghostty;
      desktopId = "com.mitchellh.ghostty";
    };
    browser = app "Браузер." {
      package = pkgs.helium;
      desktopId = "helium";
    };
    fileManager = app "Файловый менеджер." {
      package = pkgs.nautilus;
      desktopId = "org.gnome.Nautilus";
    };
  };

  config = {
    # Списком, а не обходом cfg: в custom.apps лежат и переключатели групп.
    environment.systemPackages = map (role: cfg.${role}.package) roles ++ [
      # Кто по старинке зовёт xterm, получает настоящий терминал.
      (pkgs.writeShellScriptBin "xterm" ''
        if [ "''${1:-}" = "-e" ]; then
          shift
          exec ${lib.getExe cfg.terminal.package} -e "$@"
        fi
        exec ${lib.getExe cfg.terminal.package} "$@"
      '')
    ];

    # Через PAM, а не home.sessionVariables: те читают только логин-шеллы,
    # и в графическом сеансе переменных не было бы вовсе.
    environment.sessionVariables = {
      TERMINAL = cfg.terminal.command;
      BROWSER = cfg.browser.command;
    };

    hm.xdg.terminal-exec = {
      enable = true;
      settings.default = [ (desktop "terminal") ];
    };

    # Запасные ассоциации в /etc/xdg. Личный ~/.config/mimeapps.list — его
    # правят сами программы — перекрывает их там, где задаёт своё.
    xdg.mime.defaultApplications =
      lib.genAttrs [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
        "text/html"
        "application/xhtml+xml"
      ] (_: desktop "browser")
      // lib.genAttrs [
        "inode/directory"
        "application/x-gnome-saved-search"
      ] (_: desktop "fileManager");
  };
}
