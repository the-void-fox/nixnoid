{ pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # приоритет реального времени для PipeWire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    wireplumber.extraConfig = {
      "10-bluez"."monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
      };

      # Наушники всегда остаются в A2DP. Иначе wireplumber переводит их в
      # профиль гарнитуры, как только кто-то открывает микрофон: A2DP-выход
      # исчезает, звук уходит во встроенное гнездо, где ничего нет, — «звук
      # пропал». Микрофон гарнитуры не нужен: есть отдельный USB-микрофон.
      "11-bluez-no-autoswitch"."wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
  };

  environment.systemPackages = [ pkgs.alsa-utils ];
}
