# `screenshot [region|screen|annotate]` — для сессий без своего скриншотера
# (mango, driftwm). Снимки ложатся туда же и с теми же именами, что у niri.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom.desktop.screenshot.enable = lib.mkEnableOption "команду screenshot";

  config = lib.mkIf config.custom.desktop.screenshot.enable {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "screenshot";
        runtimeInputs = with pkgs; [
          coreutils
          grim
          libnotify
          satty
          slurp
          wl-clipboard
        ];
        text = builtins.readFile ./screenshot.sh;
      })
    ];
  };
}
