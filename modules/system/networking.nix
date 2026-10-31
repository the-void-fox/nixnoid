{ config, lib, ... }:

let
  cfg = config.custom.network;
in
{
  options.custom.network = {
    dnscrypt.enable = lib.mkEnableOption "DNS только через dnscrypt-proxy" // {
      default = true;
      description = ''
        Все имена резолвит локальный dnscrypt-proxy, шифрованно. Выключено —
        DNS снова раздаёт NetworkManager: от роутера, открытым текстом, зато
        без сюрпризов в гостиничном Wi-Fi.
      '';
    };

    tailscale = {
      enable = lib.mkEnableOption "Tailscale" // {
        default = true;
      };
      exitNode = lib.mkEnableOption "роль выходного узла тайлнета" // {
        default = true;
      };
    };
  };

  config = lib.mkMerge [
    {
      networking = {
        networkmanager = {
          enable = true;
          wifi.macAddress = "random";
          wifi.scanRandMacAddress = true;
          ethernet.macAddress = "random";
        };

        firewall = {
          enable = true;
          allowPing = false;
          # Попытки соединения — в журнал. Каждый отброшенный пакет — нет: роутер
          # без конца шлёт широковещание, и это было две трети всего журнала.
          logRefusedConnections = true;
          logRefusedPackets = false;
        };
      };

      boot.kernel.sysctl = {
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

    (lib.mkIf cfg.dnscrypt.enable {
      # resolv.conf не трогать: иначе DNS от роутера шёл бы мимо
      # dnscrypt-proxy, открытым текстом. Force — потому что systemd-resolved
      # (его включает AmneziaVPN) просит "systemd-resolved", и тогда тот же
      # DNS роутера попадал бы в resolved.
      networking.networkmanager.dns = lib.mkForce "none";

      # Единственный резолвер — dnscrypt-proxy. Обратная сторона: упал он — DNS
      # нет совсем, а captive-порталы (гостиничный Wi-Fi) через него не пускают;
      # там временно выключи custom.network.dnscrypt.
      networking.nameservers = [ "127.0.0.1" ];

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
    })

    # Выходной узел тайлнета. Серые адреса с обеих сторон не мешают: машины сами
    # ходят к координатору, а не пробьются — трафик пойдёт через DERP. Кроме
    # rebuild нужно один раз руками:
    #   1. sudo tailscale up
    #   2. в https://login.tailscale.com/admin/machines отметить Exit Node.
    # Проверка: в `tailscale status` у этой машины — «offers exit node».
    (lib.mkIf cfg.tailscale.enable {
      services.tailscale = {
        enable = true;
        # "client" — пользоваться чужими выходными узлами, "both" — ещё и быть
        # им; начиная с "server" включается форвардинг.
        useRoutingFeatures = if cfg.tailscale.exitNode then "both" else "client";
        extraUpFlags = [
          "--accept-dns=false" # иначе MagicDNS забирает резолвинг у dnscrypt-proxy
        ]
        ++ lib.optional cfg.tailscale.exitNode "--advertise-exit-node";
      };
    })

    {
      # Выходному узлу и VPN-туннелям нужен loose: ответ приходит на туннель, а
      # маршрут к источнику лежит через физический интерфейс, и strict такие
      # пакеты молча выбрасывает. От подмены адресов loose всё равно защищает.
      # Без туннелей — strict.
      boot.kernel.sysctl =
        let
          rp = if cfg.tailscale.enable || config.custom.vpn.tunnels then 2 else 1;
        in
        {
          "net.ipv4.conf.all.rp_filter" = rp;
          "net.ipv4.conf.default.rp_filter" = rp;
        };
    }
  ];
}
