{ pkgs, ... }:

{
  # ── Bluetooth ────────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Intel Bluetooth (8087:0aaa) на холодном старте иногда не загружает прошивку
  # («FW download error recovery failed (-19)»). Не даём ему засыпать: btusb —
  # с момента загрузки драйвера, правило udev ниже — на само устройство.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';

  # ── Игровые контроллеры ──────────────────────────────────────────────────────
  hardware.xone.enable = true; # Xbox, проводные и через донгл
  hardware.xpadneo.enable = true; # Xbox по Bluetooth

  # ── Мышь и клавиатура ────────────────────────────────────────────────────────
  programs.solaar.enable = true; # Logitech Unifying/Bolt
  services.ratbagd.enable = true; # игровые мыши: piper — его морда

  # ── Мониторы по DDC/CI ───────────────────────────────────────────────────────
  # Яркость внешних мониторов: ddcutil, и noctalia через него же.
  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    piper
    ddcutil
  ];

  services.udev = {
    packages = [ pkgs.game-devices-udev-rules ];

    extraRules = ''
      # /dev/rfkill — залогиненному пользователю. Единственное правило, ради
      # которого раньше тянулся весь gnome-settings-daemon.
      KERNEL=="rfkill", SUBSYSTEM=="misc", TAG+="uaccess"

      # Стрим-панель Mad Dog GK150K (HID, 0c00:1000).
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0c00", ATTRS{idProduct}=="1000", MODE="0660", TAG+="uaccess"
      SUBSYSTEM=="usb",    ATTRS{idVendor}=="0c00", ATTRS{idProduct}=="1000", MODE="0660", TAG+="uaccess"

      # Intel Bluetooth — без autosuspend (см. btusb выше).
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0aaa", TEST=="power/control", ATTR{power/control}="on"
    '';
  };
}
