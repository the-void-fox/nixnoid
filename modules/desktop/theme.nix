# Внешний вид для всех сессий: тёмная Adwaita у GTK и Qt, курсор и шрифты.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.custom.desktop) cursor fonts;

  fontPackages = builtins.filter lib.isDerivation config.fonts.packages;

  # Умолчания fontconfig в его собственном виде — для песочниц Flatpak.
  aliases = lib.concatStrings (
    lib.mapAttrsToList
      (generic: families: ''
        <alias binding="same">
          <family>${generic}</family>
          <prefer>${lib.concatMapStrings (f: "<family>${f}</family>") families}</prefer>
        </alias>
      '')
      {
        sans-serif = fonts.sansSerif;
        inherit (fonts) serif monospace emoji;
      }
  );

  # fontconfig для песочниц Flatpak. Шрифтов NixOS там почти нет (Noto, CJK и
  # Adwaita Sans рантайм не видит), а умолчания — свои. Этот файл подключает
  # настройки рантайма и добавляет к ним системные шрифты и те же умолчания.
  flatpakFonts = pkgs.writeText "flatpak-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
      ${lib.concatMapStrings (p: "<dir>${p}</dir>") fontPackages}
      ${aliases}
    </fontconfig>
  '';
in
{
  options.custom.desktop.cursor = lib.mkOption {
    type = lib.types.attrs;
    default = {
      # Без суффикса -Right: в Bibata это зеркальная, леворукая раскладка.
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    description = "Курсор для всех сессий и приложений.";
  };

  options.custom.desktop.fonts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = {
      # Шрифты интерфейса GNOME: их же просят GTK и портал настроек hyprstack.
      sansSerif = [
        "Adwaita Sans"
        "Noto Sans"
      ];
      serif = [ "Noto Serif" ];
      monospace = [
        "Adwaita Mono"
        "Noto Sans Mono"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
    description = ''
      Шрифты по умолчанию (sansSerif, serif, monospace, emoji) — для всех
      сессий и приложений, включая Steam и Flatpak.
    '';
  };

  config = {
    hm = {
      home.pointerCursor = cursor // {
        enable = true;
        gtk.enable = true;
      };

      gtk = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        # Округлая Adwaita, та же, что по умолчанию. Задана явно ради Qt (ниже).
        iconTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
      };

      # qgnomeplatform берёт тему иконок из gsettings, а не из gtk settings.ini:
      # без этой строки у Qt (и у Quickshell-оболочек) иконки были бы другие.
      dconf.settings."org/gnome/desktop/interface".icon-theme = "Adwaita";
    };

    # Курсор — ещё и через PAM: pointerCursor экспортирует XCURSOR_* лишь в
    # логин-шеллы, а композиторы, которые читают окружение, иначе берут Adwaita.
    environment.sessionVariables = {
      XCURSOR_THEME = cursor.name;
      XCURSOR_SIZE = toString cursor.size;
    };

    # Qt — той же тёмной Adwaita. Цвета qgnomeplatform берёт из настроек GTK,
    # так что это одно семейство, но не попиксельное совпадение.
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    fonts = {
      # Список — явный. enableDefaultPackages (его включает graphical-desktop.nix)
      # приносил ещё unifont, FreeFont и TeX Gyre: лишние кандидаты в замену,
      # когда нужного шрифта нет.
      enableDefaultPackages = false;
      packages = with pkgs; [
        adwaita-fonts # Adwaita Sans и Mono: без них GNOME-приложения брали Noto Sans
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        dejavu_fonts
        liberation_ttf
        corefonts
        vista-fonts
      ];
      fontconfig.defaultFonts = fonts;
    };

    # Steam читает только пользовательский fontconfig (см. описание
    # programs.steam.fontPackages), поэтому умолчания — ещё и туда.
    hm.fonts.fontconfig.defaultFonts = fonts;

    # Flatpak: шрифты и курсор NixOS — симлинки в /nix/store, которого в
    # песочнице нет, поэтому там не было ни Noto, ни Bibata. Открываем на
    # чтение только эти пакеты, а не весь store, и подставляем свой fontconfig.
    services.flatpak.overrides.settings.global = {
      Context.filesystems = map (p: "${p}:ro") (
        fontPackages
        ++ [
          flatpakFonts
          cursor.package
        ]
      );
      Environment = {
        FONTCONFIG_FILE = "${flatpakFonts}";
        XCURSOR_PATH = "${cursor.package}/share/icons";
      };
    };
  };
}
