# Утилиты на каждый день: терминал, система, заметки, мелочи.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  terminal = lib.getExe config.custom.apps.terminal.package;
in
{
  environment.systemPackages = with pkgs; [
    # micro с исправленным ярлыком. Штатный отдаёт запуск терминала GLib, а
    # та зовёт `xdg-terminal-exec -e`, которого xdg-terminal-exec не знает:
    # ни двойной клик по файлу, ни «Открыть в Micro» не работали. Ярлык зовёт
    # терминал сам; имя файла прежнее, так что ассоциации не сбиваются.
    (micro.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/share/applications/micro.desktop \
          --replace-fail "Exec=micro %F" "Exec=${terminal} -e micro %F" \
          --replace-fail "Terminal=true" "Terminal=false"
      '';
    }))

    # На них смотрят глобальные алиасы (shell/default.nix), поэтому — в системе.
    bat
    cyme
    doggo
    duf
    eza
    fd
    procs
    xcp

    fastfetch
    glib # gdbus, gsettings, gio
    htop
    ripgrep
    tree

    tesseract # распознавание текста
    wtype
    xdotool
    xmrig # майнер Monero
  ];

  environment.variables.EDITOR = "micro";

  hm.home.packages = with pkgs; [
    neovim
    bottom
    erdtree
    wl-clipboard
    cbonsai
    mission-center
    obsidian
    monero-gui
  ];

  services.flatpak.packages = [ "app.drey.Dialect" ]; # переводчик
}
