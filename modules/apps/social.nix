# Связь: мессенджеры, звонки, удалённый доступ, телефон.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom.apps.social.enable =
    lib.mkEnableOption "мессенджеры, KDE Connect, удалённый доступ"
    // {
      default = true;
    };

  config = lib.mkIf config.custom.apps.social.enable {
    # Телефон рядом с ПК. Порты 1714–1764 модуль открывает сам.
    programs.kdeconnect.enable = true;

    hm.home.packages = with pkgs; [
      ayugram-desktop
      void-connect # свой P2P-мессенджер для локальной сети
      zoom-us
      rustdesk
    ];

    services.flatpak.packages = [ "dev.vencord.Vesktop" ]; # Discord

    # VoidConnect: 7700–7704 (основной порт, чат и прочее) — только из локальной
    # сети. Диск переносной, имена интерфейсов разные, поэтому фильтр по адресу
    # отправителя, а не по интерфейсу: в чужом Wi-Fi порты всё равно видны лишь
    # соседям по сети, но не из интернета.
    networking.firewall.extraCommands = ''
      for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
        iptables -A nixos-fw -s "$net" -p tcp --dport 7700:7704 -j nixos-fw-accept
        iptables -A nixos-fw -s "$net" -p udp --dport 7700:7704 -j nixos-fw-accept
      done
    '';
  };
}
