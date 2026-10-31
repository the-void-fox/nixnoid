# hyprstack — оболочка над Hyprland: панель, лаунчер, свои диалоги и порталы.
# Hyprland ставит её же модуль, отдельный вход для него не нужен.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  apps = config.custom.apps;

  # ID темы hyprstack — имя файла, если оно вида hyprstack-custom-<16 hex>,
  # иначе sha256 от имени (catalogue() в shell/assets/theme_manager.py).
  # Отсюда «нечитаемые» имена: только так ID предсказуем.
  #   …0c0c0c0cfafafafa — Monochrome: ни одной цветной роли;
  #   …0d0d0d0dfbfbfbfb — Monochrome Signal: цветные ошибка, успех и ANSI.
  themes = lib.mapAttrs' (
    file: _: lib.nameValuePair (lib.removeSuffix ".json" file) ./themes/${file}
  ) (builtins.readDir ./themes);
  theme = "hyprstack-custom-0c0c0c0cfafafafa";
  css = import ./colors.nix themes.${theme};

  vars = import ./vars.nix {
    inherit apps;
    inherit (config.custom.desktop) cursor;
  };

  # Общее с остальной системой — из Nix: переменные (через PAM они тоже
  # приходят, а так гарантированно доходят до всего, что запускает композитор)
  # и мониторы из пульта.
  fromNix = ''
    hl.env("TERMINAL", "${apps.terminal.command}")
    hl.env("BROWSER", "${apps.browser.command}")
  ''
  + lib.concatMapStrings (m: ''
    hl.monitor({ output = "${m.name}", mode = "${m.mode}", position = "${m.position}", scale = ${m.scale} })
  '') (lib.attrValues config.custom.desktop.monitors)
  + autostart;

  # Автозапуск из пульта. Номер стола — местный, как на панели; в номер
  # Hyprland его переводит сама hyprstack (workspace_base). Правило exec_cmd
  # привязано к запущенному процессу и живёт минуту, так что окна, открытые
  # потом руками, ложатся как обычно.
  autostart = lib.optionalString (config.custom.desktop.autostart != { }) ''
    hl.on("hyprland.start", function()
        local layouts = hyprstack_layouts
        for _, app in ipairs({
    ${
      lib.concatStrings (
        lib.mapAttrsToList (
          monitor: apps:
          lib.concatStrings (
            lib.mapAttrsToList (number: command: ''
              { monitor = "${monitor}", number = ${number}, command = ${builtins.toJSON command} },
            '') apps
          )
        ) config.custom.desktop.autostart
      )
    }    }) do
            local base = layouts and layouts.workspace_base and layouts.workspace_base(app.monitor) or 0
            hl.exec_cmd(app.command, { workspace = (base + app.number) .. " silent", maximize = true })
        end
    end)
  '';
in
{
  # Модуль лишь объявляет programs.hyprstack.*, включается он ниже.
  imports = [ inputs.hyprstack.nixosModules.default ];

  config = lib.mkIf (lib.elem "hyprstack" config.custom.desktop.sessions) {
    programs.hyprstack.enable = true;

    # Апстримный hyprstack лишь PartOf= к graphical-session.target, но сам его
    # не поднимает, а вручную этот target не запустить. Без него молчит всё,
    # что он запускает: уведомления USBGuard, а с xdg-desktop-portal 1.22 и
    # сами порталы (у них Requisite=). В ветке portals это уже исправлено,
    # повтор здесь — для сборки из апстрима.
    systemd.user.services.hyprstack-session = {
      wants = [ "graphical-session.target" ];
      before = [ "graphical-session.target" ];
    };

    # Порталы — явно. Секция в нижнем регистре: XDG_CURRENT_DESKTOP=Hyprland
    # превращается в hyprland-portals.conf.
    #
    # xdg-desktop-portal-gnome сюда не годится: у него Requisite=
    # graphical-session.target, и пока hyprstack этот target не поднимал (см.
    # hyprstack-session выше), портал падал с «Dependency failed», и выбор
    # файла пропадал во всех программах.
    xdg.portal.config.hyprland = {
      default = [ "gtk" ];
      # Отвечает сама оболочка (её backend живёт в процессе hyprstack-shell);
      # gtk — запасной, пока она не запущена.
      "org.freedesktop.impl.portal.FileChooser" = [
        "hyprstack"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Settings" = [
        "hyprstack"
        "gtk"
      ];
      # Захват экрана умеет только реализация hyprland.
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      # gtk пересылает уведомления штатному демону, то есть всё той же оболочке.
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    };

    hm =
      { config, lib, ... }:
      {
        imports = [ inputs.hyprstack.homeManagerModules.default ];

        # extraConfig подключается последним — после keybinds.lua и layouts.lua,
        # поэтому перебивает любой бинд.
        programs.hyprstack = {
          enable = true;
          extraConfig = fromNix + builtins.readFile ./extra.lua;
        };

        gtk.gtk3.extraCss = css.gtk3;
        gtk.gtk4.extraCss = css.gtk4;

        xdg.configFile = {
          # force: hyprstack при первом запуске кладёт сюда свой файл, и
          # home-manager отказался бы его заменить.
          "hyprstack/hypr-vars.lua" = {
            text = "return " + lib.generators.toLua { } vars + "\n";
            force = true;
          };
          "gtk-3.0/gtk.css".force = true;
          "gtk-4.0/gtk.css".force = true;
        }
        // lib.mapAttrs' (
          id: file: lib.nameValuePair "hyprstack/themes/${id}.json" { source = file; }
        ) themes;

        # Файловый диалог hyprstack просит иконку по MIME-типу, а запасной —
        # application-x-zerosize (имя из KDE). В Adwaita нет ни того ни другого,
        # и на месте иконок были фиолетово-чёрные заглушки. Хватает одной
        # запасной рядом с темой: иконки ищутся во всех XDG_DATA_DIRS, а правка
        # самого пакета выбила бы из кэша 217 зависимых.
        xdg.dataFile."icons/Adwaita/scalable/mimetypes/application-x-zerosize.svg".source =
          "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/scalable/mimetypes/text-x-generic.svg";

        # Выбранная тема — состояние пользователя (state/scheme.json), её же
        # меняет GUI, поэтому применяется один раз, а не на каждый rebuild.
        # Вручную: hyprstack scheme set -n <ID темы> -m dark
        home.activation.hyprstackTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          marker="${config.xdg.stateHome}/hyprstack/.monochrome-applied"
          if [ ! -e "$marker" ]; then
            if run ${lib.getExe' config.programs.hyprstack.package "hyprstack"} scheme set -n ${theme} -m dark; then
              run mkdir -p "$(dirname "$marker")"
              run touch "$marker"
            else
              warnEcho "hyprstack: не удалось применить тему ${theme}, примени вручную"
            fi
          fi
        '';
      };
  };
}
