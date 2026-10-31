{
  networking = {
    networkmanager = {
      enable = true;
      wifi.macAddress = "random";
      wifi.scanRandMacAddress = true;
      ethernet.macAddress = "random";

      # resolv.conf не трогать: иначе DNS от роутера шёл бы мимо
      # dnscrypt-proxy, открытым текстом.
      dns = "none";
    };

    # Единственный резолвер — dnscrypt-proxy. Обратная сторона: упал он — DNS
    # нет совсем, а captive-порталы (гостиничный Wi-Fi) через него не пускают;
    # там временно верни NetworkManager в dns = "default".
    nameservers = [ "127.0.0.1" ];

    firewall = {
      enable = true;
      allowPing = false;
      # Попытки соединения — в журнал. Каждый отброшенный пакет — нет: роутер
      # без конца шлёт широковещание, и это было две трети всего журнала.
      logRefusedConnections = true;
      logRefusedPackets = false;
    };
  };

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      server_names = [
        "cloudflare"
        "quad9-dnscrypt-ip4-filter-pri"
      ];
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = false;
      ipv6_servers = false;
      block_ipv6 = true;

      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;
      cache_neg_min_ttl = 60;
      cache_neg_max_ttl = 600;
    };
  };

  # Выходной узел тайлнета. Серые адреса с обеих сторон не мешают: машины сами
  # ходят к координатору, а не пробьются — трафик пойдёт через DERP. Кроме
  # rebuild нужно один раз руками:
  #   1. sudo tailscale up
  #   2. в https://login.tailscale.com/admin/machines отметить Exit Node.
  # Проверка: в `tailscale status` у этой машины — «offers exit node».
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both"; # начиная с "server" включается форвардинг
    extraUpFlags = [
      "--advertise-exit-node"
      "--accept-dns=false" # иначе MagicDNS забирает резолвинг у dnscrypt-proxy
    ];
  };

  boot.kernel.sysctl = {
    # Выходному узлу нужен loose: ответ приходит на tailscale0, а маршрут к
    # источнику лежит через физический интерфейс, и strict такие пакеты молча
    # выбрасывает. От подмены адресов loose всё равно защищает.
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;

    # BBR вместо cubic: на дальних соединениях (кэш nixpkgs, git, Steam)
    # потери есть всегда, и cubic зря сбрасывает скорость. fq для BBR обязателен.
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";

    # Окна побольше, чтобы дальний канал не простаивал в ожидании подтверждений.
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 131072 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };
  boot.kernelModules = [ "tcp_bbr" ];
}
