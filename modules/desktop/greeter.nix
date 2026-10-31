# Окно входа: greetd запускает ReGreet внутри cage — киоска на один экран.
{ config, pkgs, ... }:

{
  services.displayManager.regreet = {
    enable = true;
    extraCss = ./assets/regreet.css;
    settings.GTK.application_prefer_dark_theme = true;
  };

  services.greetd.settings.default_session.command =
    "env GSK_RENDERER=ngl ${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";

  # Обои читает regreet.css отсюда.
  environment.etc."greetd/wallpaper.jpg".source = config.custom.desktop.wallpaper;

  users.users.greeter.extraGroups = [
    "video"
    "render"
    "input"
  ];
}
