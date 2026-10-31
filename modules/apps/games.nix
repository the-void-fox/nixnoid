# Игры: Steam, Wine и Proton, лаунчеры, моды, стриминг.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotnet = pkgs.dotnetCorePackages.runtime_10_0;
in
{
  options.custom.apps.games.enable = lib.mkEnableOption "игры: Steam, Wine, Proton, лаунчеры" // {
    default = true;
  };

  config = lib.mkIf config.custom.apps.games.enable {
    programs.steam.enable = true;
    programs.gamemode.enable = true; # на время игры — частоты, приоритеты, GPU

    environment.systemPackages = with pkgs; [
      # Пакетом, а не programs.gamescope: модуль оставляет в PATH только
      # gamescope и gamescopectl, без gamescopestream и gamescope-type.
      gamescope
      mangohud
      wineWow64Packages.stable
      winetricks
      dotnet

      # Proton вне Steam. 32-битная графика ему нужна своя.
      (umu-launcher.override {
        extraPkgs =
          pkgs: with pkgs.pkgsi686Linux; [
            mesa
            libdrm
            libGL
            libglvnd
            vulkan-loader
          ];
      })
    ];

    # Где .NET-программам искать рантайм.
    environment.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";

    hm.home.packages = with pkgs; [
      prismlauncher
      beyond-all-reason
      hydra-launcher
      protonup-qt
      steamcmd
      scanmem

      # Моды RimWorld: свой менеджер и RimSort — с путями к схемам GSettings,
      # без которых тот не обходится.
      rust-rim
      (symlinkJoin {
        name = "rimsort";
        paths = [ rimsort ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/rimsort \
            --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
            --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}"
        '';
      })
    ];

    services.flatpak.packages = [
      "com.usebottles.bottles"
      "ru.linux_gaming.PortProton"
      "io.github.zaedus.spider" # пасьянс «Паук»
    ];

    # Sunshine — стрим игр на свои устройства. Выключен; включишь — порты
    # откроются, но только внутри тайлнета.
    services.sunshine = {
      enable = false;
      autoStart = false;
      capSysAdmin = true;
    };
    networking.firewall.interfaces.tailscale0 = lib.mkIf config.services.sunshine.enable {
      allowedTCPPorts = [
        47984
        47989
        47990
        48010
      ];
      allowedUDPPorts = [
        47998
        47999
        48000
        48002
        48010
      ];
    };
  };
}
