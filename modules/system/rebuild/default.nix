# `rebuild` — пересборка системы с автокоммитом конфига. Справка: rebuild -h.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom.rebuild.localInputs = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      hyprstack = "/home/me/src/hyprstack-shell";
    };
    description = "Локальные копии входов флейка для `rebuild --local <вход>`.";
  };

  config = {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "rebuild";
        # nixos-rebuild и sudo — системные, из PATH: sudo обязан быть setuid-обёрткой.
        runtimeInputs = with pkgs; [
          coreutils
          git
          gnugrep
        ];
        runtimeEnv = {
          FLAKE = config.custom.repo;
          HOST = config.networking.hostName;
          LOCAL_INPUTS = config.custom.rebuild.localInputs;
        };
        text = builtins.readFile ./ui.sh + builtins.readFile ./rebuild.sh;
      })
    ];

    environment.shellAliases = {
      update = "rebuild --update";
      garbage = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    };
  };
}
