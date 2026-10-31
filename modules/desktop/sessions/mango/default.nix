# mango — тайлинг на тегах (dwl на wlroots): набор раскладок на выбор и
# обзор окон. Панель и лаунчер — noctalia.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # mango и noctalia говорят по dwl-ipc, а его вырезали в mango 0.16. В nixpkgs
  # уже 0.18: с ним у noctalia пропадают рабочие столы, лаунчер и выход, а
  # config.conf не проходит проверку (exec-once, tagrule, monitorrule и ещё
  # два десятка ключей — «Unknown keyword»). Поэтому mango — из того же снимка
  # nixpkgs, к которому прибита noctalia: там 0.14.4, и эта пара понимает друг
  # друга. Обновишь noctalia — пересмотри и это.
  mango = inputs.noctalia.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mango;

  # Та же сессия, что в пакете, но с выводом в журнал: journalctl --user -t mango
  session = pkgs.symlinkJoin {
    name = "mango-session";
    paths = [ mango ];
    postBuild = ''
      rm -f $out/share/wayland-sessions/mango.desktop
      cat > $out/share/wayland-sessions/mango.desktop <<EOF
      [Desktop Entry]
      Name=Mango
      DesktopNames=mango;wlroots
      Comment=mango (журнал: journalctl --user -t mango)
      Exec=${pkgs.systemd}/bin/systemd-cat -t mango ${mango}/bin/mango
      Type=Application
      EOF
    '';
    # sessionPackages берёт только пакеты с этим атрибутом, а symlinkJoin его
    # не наследует.
    passthru.providedSessions = [ "mango" ];
  };

  layout = pkgs.writeShellApplication {
    name = "mango-layout";
    runtimeInputs = [
      mango # mmsg
      pkgs.gawk
      pkgs.rofi
    ];
    text = builtins.readFile ./mango-layout.sh;
  };

  home = config.users.users.${config.custom.user}.home;
  inherit (config.custom.desktop) cursor;

  # Координаты у mango только неотрицательные: раскладка сдвигается так,
  # чтобы самый левый и самый верхний край пришлись на ноль.
  monitors = lib.attrValues config.custom.desktop.monitors;
  shift = axis: -(lib.foldl' lib.min 0 (map (m: m.${axis}) monitors));
  monitorRules = lib.concatMapStrings (
    m:
    "monitorrule=name:${m.name},width:${toString m.width},height:${toString m.height},"
    + "refresh:${toString m.hz},x:${toString (m.x + shift "x")},y:${toString (m.y + shift "y")},"
    + "scale:${m.scale}\n"
  ) monitors;
in
{
  config = lib.mkIf (lib.elem "mango" config.custom.desktop.sessions) {
    custom.desktop = {
      noctalia.enable = true;
      screenshot.enable = true;
      wlrPortal.desktops = [ "mango" ]; # mango сам выставляет XDG_CURRENT_DESKTOP=mango
    };

    services.displayManager.sessionPackages = [ session ];

    environment.systemPackages = [
      mango # mmsg: noctalia зовёт его по имени
      layout
      pkgs.brightnessctl # клавиши яркости из config.conf
      pkgs.playerctl # медиаклавиши из config.conf
    ];

    # Заготовка под тему: config.conf подключает её всегда, а noctalia создаёт
    # файл лишь при первой генерации. «f» не трогает уже существующий файл, и
    # это обычный файл, а не ссылка home-manager, — noctalia его перезаписывает.
    systemd.user.tmpfiles.users.${config.custom.user}.rules = [
      "d %h/.config/mango 0755 - - -"
      "f %h/.config/mango/noctalia.conf 0644 - - -"
    ];

    hm = {
      xdg.configFile = {
        # noctalia после генерации темы зовёт template-apply.sh, а тот ищет в
        # конфиге буквальную строку «source = <путь>». Не найдя, он заменяет
        # ссылку home-manager своей копией — то есть сносит этот конфиг.
        # Поэтому рабочая строка — как в документации mango, а вторая,
        # с пробелами, — только маркер для скрипта.
        "mango/config.conf" = {
          force = true;
          text = ''
            source=${home}/.config/mango/noctalia.conf
            # маркер для template-apply.sh: source = ${home}/.config/mango/noctalia.conf
            cursor_theme=${cursor.name}
            cursor_size=${toString cursor.size}
            ${monitorRules}
          ''
          + builtins.readFile ./config.conf;
        };

        # Тема rofi в цвет noctalia — для любого вызова rofi, не только меню раскладок.
        "rofi/config.rasi" = {
          source = ./rofi.rasi;
          force = true;
        };
      };

      # Индикатор раскладки окон — в начало правой части панели:
      #   текст  — поток `mango-layout watch`, обновляется мгновенно;
      #   ЛКМ    — меню всех раскладок; колесо — перебор по кругу.
      programs.noctalia-shell.settings = {
        bar.widgets.right = lib.mkBefore [
          {
            id = "CustomButton";
            icon = "layout-grid";
            textCommand = "mango-layout watch";
            textStream = true;
            leftClickExec = "mango-layout menu";
            wheelMode = "unified";
            wheelExec = "mango-layout next";
          }
        ];
        # Шаблон красит рамки окон в цвета схемы noctalia
        # (~/.config/mango/noctalia.conf, подключён в config.conf).
        templates.activeTemplates = [
          {
            id = "mango";
            enabled = true;
          }
        ];
      };
    };
  };
}
