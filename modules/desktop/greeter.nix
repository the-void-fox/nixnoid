# Окно входа: greetd запускает ReGreet внутри cage — киоска на один экран.
{ pkgs, ... }:

{
  services.displayManager.regreet = {
    enable = true;
    extraCss = ./assets/regreet.css;
    settings.GTK.application_prefer_dark_theme = true;
  };

  services.greetd.settings.default_session.command =
    "env GSK_RENDERER=ngl ${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";

  # Обои читает regreet.css отсюда. Снежинка из nixos-artwork, а не своя копия.
  environment.etc."greetd/wallpaper.jpg".source =
    "${pkgs.nixos-artwork.wallpapers.binary-black}/share/backgrounds/nixos/nix-wallpaper-binary-black.png";

  users.users.greeter.extraGroups = [
    "video"
    "render"
    "input"
  ];
}
