# Портал wlroots — демонстрация экрана и снимки для сессий, которые его сами
# не настраивают (mango, driftwm). Оба композитора отдают картинку по
# zwlr_screencopy, не хватало только бэкенда, который её заберёт.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  desktops = config.custom.desktop.wlrPortal.desktops;
in
{
  options.custom.desktop.wlrPortal.desktops = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Значения XDG_CURRENT_DESKTOP, которым нужен портал wlroots.";
  };

  config = lib.mkIf (desktops != [ ]) {
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

      # Явно: в UseIn у wlr.portal этих сессий нет, и сам он бы не выбрался —
      # ScreenCast ушёл бы в портал GNOME, которому тут не с кем говорить.
      config = lib.genAttrs desktops (_: {
        default = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "wlr";
        "org.freedesktop.impl.portal.Screenshot" = "wlr";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
        "org.freedesktop.impl.portal.Inhibit" = "none";
      });
    };

    # Что показывать, выбирается мышью — монитор или область прямо на экране.
    # Без этого файла xdp-wlr не спрашивает и берёт что попало.
    hm.xdg.configFile."xdg-desktop-portal-wlr/config".text = ''
      [screencast]
      chooser_type=simple
      chooser_cmd=${pkgs.slurp}/bin/slurp -f %o -or
      max_fps=60
    '';
  };
}
