{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  keys = config.boot.lanzaboote.pkiBundle;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # sbctl — проверить подписи (`sudo sbctl verify`) и записать ключи в
  # прошивку (`sudo sbctl enroll-keys --microsoft`). Сам он ищет ключи в
  # /var/lib/sbctl, а lanzaboote подписывает теми, что в pkiBundle, — путь
  # задан явно, в том же виде, что пишет сам lanzaboote при autoEnrollKeys.
  environment.systemPackages = [ pkgs.sbctl ];
  environment.etc."sbctl/sbctl.conf".text = ''
    keydir: ${keys}/keys
    guid: ${keys}/GUID
  '';

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
