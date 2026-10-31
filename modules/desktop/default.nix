# Рабочий стол. Сессия — каталог в ./sessions; включаются они списком
# custom.desktop.sessions в пульте. Общие детали (noctalia, портал wlroots,
# скриншоты) лежат в ./components и включаются только сессиями, которым нужны.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  available = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./sessions)
  );
in
{
  imports = [
    ./apps.nix
    ./greeter.nix
    ./monitors.nix
    ./theme.nix
    ./components/noctalia
    ./components/screenshot
    ./components/wlr-portal.nix
  ]
  ++ map (name: ./sessions/${name}) available;

  options.custom.desktop.autostart = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    default = { };
    example = {
      DP-3."1" = "helium";
    };
    description = ''
      Что запускать при входе: монитор → номер стола на нём → команда. Окна
      открываются развёрнутыми. Поддерживает hyprstack.
    '';
  };

  options.custom.desktop.sessions = lib.mkOption {
    type = lib.types.nonEmptyListOf (lib.types.enum available);
    description = "Сессии в окне входа. Доступны: ${lib.concatStringsSep ", " available}.";
  };

  config = {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "desktop-env";
        runtimeInputs = with pkgs; [
          coreutils
          gawk
        ];
        runtimeEnv = {
          PANEL = "${config.custom.repo}/configuration.nix";
          AVAILABLE = available;
          CURRENT = config.custom.desktop.sessions;
        };
        text = builtins.readFile ../system/rebuild/ui.sh + builtins.readFile ./desktop-env.sh;
      })
    ];

    # Electron и Chromium — нативно в Wayland, а не через XWayland с размытым
    # текстом. NIXOS_OZONE_WL понимают обёртки nixpkgs, ELECTRON_* — всё
    # остальное (AppImage, Flatpak).
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      ELECTRON_ENABLE_WAYLAND_IME = "1";
    };

    # Маршруты порталов каждая сессия задаёт себе сама (xdg.portal.config.<имя>).
    # Общий config.common со звёздочкой перекрывал бы их и отдавал выбор случаю.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
