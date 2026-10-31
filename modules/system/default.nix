{ lib, ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./users.nix
    ./diag
    ./rebuild
  ];

  options.custom.repo = lib.mkOption {
    type = lib.types.str;
    default = "/etc/nixos";
    description = ''
      Рабочая копия этого репозитория. Её правят rebuild, desktop-env,
      bash-theme и кнопка «Разрешить навсегда» в уведомлении USBGuard.
    '';
  };

  config = {
    # dbus-broker вместо эталонного dbus-daemon: тот же протокол, быстрее.
    services.dbus.implementation = "broker";

    # Без потолка журнал дорастал до ~3,9 ГБ на единственном SSD, и
    # journalctl отвечал десятками секунд.
    services.journald.settings.Journal = {
      SystemMaxUse = "1G";
      SystemMaxFileSize = "128M";
      MaxRetentionSec = "1month";
    };
  };
}
