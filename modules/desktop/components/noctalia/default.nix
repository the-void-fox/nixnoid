# noctalia-shell — панель, лаунчер, уведомления и OSD для niri, mango и
# driftwm. Включают её сами сессии; при одном hyprstack её в системе нет.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.custom.desktop.noctalia.enable = lib.mkEnableOption "noctalia-shell";

  config = lib.mkIf config.custom.desktop.noctalia.enable {
    environment.systemPackages = with pkgs; [
      cliphist # им noctalia пишет историю буфера обмена
      wl-clipboard
    ];

    hm = {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia-shell = {
        enable = true;
        settings = import ./settings.nix {
          home = config.users.users.${config.custom.user}.home;
          terminal = config.custom.apps.terminal.command;
        };

        # Заплатка: слой обоев (Modules/Background/Background.qml) растянут на
        # весь экран и не задаёт маску ввода, то есть забирает указатель везде.
        # В niri этого не видно, а в driftwm весь «пустой холст» оказывается
        # под обоями — панорама и зум по пустому месту не работают. Остальные
        # слои noctalia маску задают, этот один забыли.
        #
        # installPhase, а не postInstall: пакет задаёт свой installPhase и хук
        # не зовёт. replace-fail: перепишет апстрим эту строку — сборка упадёт,
        # а не оставит заплатку без действия.
        package = package.overrideAttrs (old: {
          installPhase = (old.installPhase or "") + ''
            substituteInPlace $out/share/noctalia-shell/Modules/Background/Background.qml \
              --replace-fail \
                'WlrLayershell.namespace: "noctalia-wallpaper-" + (screen?.name || "unknown")' \
                'WlrLayershell.namespace: "noctalia-wallpaper-" + (screen?.name || "unknown")

                  mask: Region {}'
          '';
        });
      };
    };
  };
}
