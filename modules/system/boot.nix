{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Secure Boot. Ключи в /etc/secureboot существуют в одном экземпляре и
    # лежат на том же диске, который защищают: умрёт диск — систему придётся
    # регистрировать в прошивке заново. Копия: `secureboot-backup <каталог>`.
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
      configurationLimit = 10; # /boot всего 1 ГБ
    };

    loader = {
      # Место systemd-boot занимает lanzaboote, но editor он читает отсюда.
      systemd-boot = {
        enable = lib.mkForce false;
        editor = false; # без правки cmdline прямо в меню загрузки
      };

      # Диск переносной: не пишем загрузочные записи в NVRAM чужих машин.
      # Грузиться через меню прошивки — EFI/BOOT/BOOTX64.EFI ставится всегда.
      efi.canTouchEfiVariables = false;
    };

    # Заставка вместо бегущих строк; она же рисует окно пароля LUKS.
    # Esc во время заставки — обычный текстовый вывод.
    plymouth = {
      enable = true;
      theme = "bgrt"; # логотип из прошивки
    };

    kernelParams = [
      "quiet"
      "splash"
      "udev.log_level=3"
    ];

    # Только err и выше. Ловишь зависание при выключении — ставь 7 и убирай
    # "quiet": финальную фазу видно только на экране, journald уже мёртв.
    # (loglevel= в kernelParams не поможет: NixOS дописывает этот последним.)
    consoleLogLevel = 4;
  };
}
