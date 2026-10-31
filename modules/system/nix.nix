{
  config,
  inputs,
  pkgs,
  ...
}:

{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ (import ../../pkgs inputs) ];
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      allowed-users = [
        "root"
        config.custom.user
      ];
      trusted-users = [ "root" ];
      require-sigs = true;
      sandbox = true;

      substituters = [
        "https://cache.nixos.org"
        # Готовые сборки свежей экосистемы Wayland (niri, noctalia и прочее),
        # которых нет в основном кэше. Без него — полчаса компиляции.
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      download-buffer-size = 104857600; # 100 МиБ
      http-connections = 12;

      # 6 ядер без HT и 15 ГБ памяти: две сборки по три потока загружают
      # машину целиком, но не выносят память. Одному тяжёлому пакету все ядра
      # отдаёт `rebuild --heavy`.
      cores = 3;
      max-jobs = 2;

      # Дерево всегда «грязное» до автокоммита rebuild.
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  # Сборки — в /var/tmp на диске: /tmp — tmpfs на половину памяти
  # (hardware/storage.nix), и тяжёлая сборка упиралась там в ENOSPC.
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

  # Чужие бинарники (скачанные программы, старые игры) ищут библиотеки по
  # стандартным путям, которых в NixOS нет; nix-ld их подкладывает.
  # Не запускается — `ldd ./программа` покажет, чего не хватает.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      glib
      glibc
      libGL
      libxkbcommon
      wayland
      alsa-lib
      libX11
      libXcursor
      libXi
      libXrandr
      libxcb
      gtk3
      cairo
      pango
      gdk-pixbuf
      freetype
      fontconfig
      dbus
      nss
      nspr
      expat
    ];
  };
}
