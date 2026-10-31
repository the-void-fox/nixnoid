# USBGuard и уведомление с кнопками на каждое заблокированное устройство.
#
# Без уведомления блокировка молчит: со стороны это выглядит как сломанный
# порт или мёртвая флешка. Готовый usbguard-notifier кнопок не умеет — в его
# бинаре нет ни одного notify_notification_add_action, — поэтому свой.
{ config, pkgs, ... }:

let
  notify = pkgs.writers.writePython3Bin "usbguard-notify" {
    libraries = with pkgs.python3Packages; [
      dbus-python
      pygobject3
    ];
    flakeIgnore = [ "E501" ]; # длинные строки
  } (builtins.readFile ./notify.py);
in
{
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "allow"; # то, что воткнуто до загрузки, — своё
    rules = builtins.readFile ./allowed.rules;

    # Сигналы DevicePresenceChanged ходят по D-Bus.
    dbus.enable = true;

    # Пользователю — доступ к IPC-сокету: иначе `usbguard allow-device`
    # из уведомления получит отказ. Цена: любой процесс от его имени может
    # разрешать устройства. От того, ради чего USBGuard стоит, — чужой
    # железки в незаблокированной машине — защита остаётся.
    IPCAllowedUsers = [
      "root"
      config.custom.user
    ];
  };

  systemd.user.services.usbguard-notify = {
    description = "Уведомления USBGuard с кнопкой «Разрешить»";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [ config.services.usbguard.package ];
    # Правила демона лежат в /nix/store, писать туда нельзя, поэтому
    # «навсегда» значит «в белый список репозитория».
    environment.USBGUARD_RULES_FILE = "${config.custom.repo}/modules/security/usbguard/allowed.rules";
    serviceConfig = {
      ExecStart = "${notify}/bin/usbguard-notify";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
