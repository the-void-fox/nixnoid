# Файлы: Nautilus с расширениями, ranger, архивы, синхронизация, торренты.
# Сам Nautilus — файловый менеджер по умолчанию (desktop/apps.nix).
{ config, pkgs, ... }:

{
  # «Открыть в терминале» — в самом Nautilus такого пункта нет. Модуль
  # подключает расширение так, что оно доходит до графического сеанса.
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = config.custom.apps.terminal.command;
  };

  services.gnome.sushi.enable = true; # просмотр по пробелу
  services.gvfs.enable = true; # корзина, сеть, телефоны

  environment.systemPackages = with pkgs; [
    turtle # git в контекстном меню
    file-roller # архивы: без него двойной клик по .zip ничего не делает

    # «Открыть в редакторе»: расширение зовёт `code`, а здесь VSCodium.
    (code-nautilus.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace code-nautilus.py \
          --replace-fail "'code'" "'codium'"
      '';
    }))
  ];

  hm.programs.ranger = {
    enable = true;
    settings = {
      preview_images = true;
      # Ghostty понимает графический протокол kitty, а ranger в nixpkgs собран
      # с Pillow — ни ueberzug, ни w3m не нужны.
      preview_images_method = "kitty";
    };
    extraConfig = ''
      default_linemode devicons
    '';
  };

  # Веб-морда — только локально. Нужна с телефона — поставь сюда
  # tailscale-адрес этой машины: снаружи тайлнета его не видно.
  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # 22000 и 21027 — сама синхронизация
    guiAddress = "127.0.0.1:8384";
  };

  services.flatpak.packages = [ "de.haeckerfelix.Fragments" ]; # торренты
}
