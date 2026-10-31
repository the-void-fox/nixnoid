{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  secureBoot = config.custom.secureBoot.enable;
  keys = config.boot.lanzaboote.pkiBundle;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.custom.secureBoot.enable = lib.mkEnableOption "Secure Boot через lanzaboote" // {
    default = true;
    description = ''
      Ядро и initrd подписываются ключами из /etc/secureboot. Выключено —
      обычный systemd-boot без подписей: так и надо ставить на новую машину,
      пока ключей нет, иначе lanzaboote не соберёт загрузчик.
    '';
  };

  config = {
    # sbctl — проверить подписи (`sudo sbctl verify`) и записать ключи в
    # прошивку (`sudo sbctl enroll-keys --microsoft`). Сам он ищет ключи в
    # /var/lib/sbctl, а lanzaboote подписывает теми, что в pkiBundle, — путь
    # задан явно, в том же виде, что пишет сам lanzaboote при autoEnrollKeys.
    environment.systemPackages = lib.optional secureBoot pkgs.sbctl;
    environment.etc."sbctl/sbctl.conf" = lib.mkIf secureBoot {
      text = ''
        keydir: ${keys}/keys
        guid: ${keys}/GUID
      '';
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;

      # Secure Boot. Ключи в /etc/secureboot существуют в одном экземпляре и
      # лежат на том же диске, который защищают: умрёт диск — систему придётся
      # регистрировать в прошивке заново. Копия: `secureboot-backup <каталог>`.
      lanzaboote = {
        enable = secureBoot;
        pkiBundle = "/etc/secureboot";
        configurationLimit = 10; # /boot всего 1 ГБ
      };

      loader = {
        # Место systemd-boot занимает lanzaboote, но editor он читает отсюда.
        systemd-boot = {
          enable = if secureBoot then lib.mkForce false else true;
          configurationLimit = 10;
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
  };
}
