# Voices of the Void — бесплатная игра с itch.io, собрана только под Windows.
# Идёт через Proton (umu), версии и обновления — официальным YeetPatch
# (https://votv.dev/patcher). Справка: votv help.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  votv = pkgs.writeShellApplication {
    name = "votv";
    # Всё, чего YeetPatch требует перед работой: на NixOS этого нет, а сам он
    # подсказывает только `apt install`. umu-run — системный, из games.nix:
    # там он собран с 32-битной графикой.
    runtimeInputs = with pkgs; [
      coreutils
      curl
      findutils
      gawk
      gnugrep
      gnused
      gnutar
      gzip
      icoutils # значок из VotV.exe
      jq
      p7zip
      xxhash
    ];
    runtimeEnv = {
      # Proton-GE из nixpkgs: обновляется вместе с системой, а не руками.
      PROTON = "${pkgs.proton-ge-bin.steamcompattool}";
      DESYNC = lib.getExe' pkgs.desync "desync";
      YEETPATCH_URL = "https://votv.dev/patcher_assets/download/YeetPatch-latest-linux.tar";
    };
    text = builtins.readFile ./votv.sh;
  };
in
{
  hm.home.packages = [
    votv
    (pkgs.makeDesktopItem {
      name = "votv";
      desktopName = "Voices of the Void";
      comment = "Через Proton; обновления — YeetPatch";
      exec = "votv";
      # Достаёт `votv icon` из VotV.exe; пока его нет — значок по умолчанию.
      icon = "votv";
      categories = [ "Game" ];
      # YeetPatch спрашивает в терминале, поэтому обновление — в нём.
      actions.update = {
        name = "Обновить (YeetPatch)";
        exec = "${lib.getExe config.custom.apps.terminal.package} -e votv update --pause";
      };
    })
  ];
}
