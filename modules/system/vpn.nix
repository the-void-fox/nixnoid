# VPN и обход блокировок. Всё выключено: включается строкой в
# configuration.nix, по способу на строку. Состояние — команда `vpn`.
#
# Способы двух родов, и разница между ними главная:
#
#   ТУННЕЛИ (amnezia, wireguard, throne.tun) забирают весь трафик системы.
#   Поднят должен быть ОДИН: два дерутся за маршрут по умолчанию, и сеть
#   пропадает совсем. Установленными могут стоять все сразу.
#
#   ПРОКСИ (throne без tun, byedpi, tor) только слушают порт на 127.0.0.1.
#   Через них идёт лишь то, что настроено на прокси (браузер, Telegram), и
#   работать они могут одновременно — и с туннелем тоже.
#
# DNS: при включённом dnscrypt (system/networking.nix) резолвит всё равно он.
# Туннель свой DNS в resolv.conf не пропишет, но запросы dnscrypt-proxy сами
# уйдут через туннель, шифрованными, так что провайдер их не видит.
# Исключение — AmneziaVPN: она ставит DNS сервера на свой интерфейс через
# systemd-resolved, и имена спрашиваются у него — тоже внутри туннеля.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.vpn;
  on = description: lib.mkEnableOption description;

  status = pkgs.writeShellApplication {
    name = "vpn";
    runtimeInputs = with pkgs; [
      iproute2
      systemd
      gnugrep
    ];
    text = ''
      echo "── Маршрут по умолчанию"
      ip route show default || true
      echo
      echo "── Туннели"
      ip -brief link | grep -E '^(tun|wg|awg|amn|tailscale|throne)' || echo "  нет"
      echo
      echo "── Службы"
      for unit in AmneziaVPN tailscaled byedpi tor; do
        systemctl is-active --quiet "$unit" && echo "  ● $unit"
      done
      echo
      echo "── Прокси на 127.0.0.1"
      ss -Hltn 'src 127.0.0.1' | grep -E ':(1080|2080|9050) ' || echo "  нет"
    '';
  };
in
{
  options.custom.vpn = {
    amnezia.enable = on ''
      AmneziaVPN — туннель с окном. AmneziaWG (WireGuard со спрятанными
      приметами), XRay, OpenVPN поверх маскировки. Ключ — от своего сервера
      или от того, кто его держит.
    '';

    wireguard.enable = on ''
      обычный WireGuard через NetworkManager. Конфиг от провайдера VPN:
      `nmcli connection import type wireguard file wg0.conf`, дальше — как
      обычное соединение. Распознаётся DPI по первому пакету.
    '';

    throne = {
      enable = on ''
        Throne — окно для подписок VLESS / VMess / Trojan / Shadowsocks /
        Hysteria. Сам по себе прокси на 127.0.0.1:2080.
      '';
      tun = on ''
        режим TUN в Throne: прокси становится туннелем на всю систему.
        Права выдаются ядру Throne через capabilities.
      '';
    };

    byedpi = {
      enable = on ''
        ByeDPI — SOCKS5 на 127.0.0.1:1080. Не VPN: сервера нет, он только
        режет и перемешивает пакеты так, что DPI не узнаёт сайт. Помогает,
        когда сайт не заблокирован по адресу.
      '';
      args = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "--split"
          "1"
          "--disorder"
          "3+s"
          "--mod-http=h,d"
          "--auto=torst"
          "--tlsrec"
          "1+s"
        ];
        description = ''
          Стратегия обхода. Универсальной нет; эта — пример из nixpkgs.
          Слушать будет всё равно только 127.0.0.1:1080.
        '';
      };
    };

    tor = {
      enable = on "Tor — SOCKS5 на 127.0.0.1:9050. Медленно, но почти всегда";
      bridges = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [ "obfs4 192.0.2.1:443 FINGERPRINT cert=… iat-mode=0" ];
        description = ''
          Мосты, если Tor напрямую не пускают. Строки — как их выдаёт
          https://bridges.torproject.org или бот @GetBridgesBot, без слова
          `Bridge`. Понимаются obfs4, webtunnel и snowflake.
        '';
      };
    };

    tunnels = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = cfg.amnezia.enable || cfg.wireguard.enable || (cfg.throne.enable && cfg.throne.tun);
      description = "Включён ли хоть один туннель. Задаётся сам, читают сеть и фаервол.";
    };
  };

  config = lib.mkMerge [
    { environment.systemPackages = [ status ]; }

    # Ответы через туннель приходят не на тот интерфейс, где лежит маршрут к
    # серверу, и строгая проверка обратного пути их режет (sysctl rp_filter
    # для того же — в system/networking.nix).
    (lib.mkIf cfg.tunnels {
      networking.firewall.checkReversePath = "loose";
    })

    (lib.mkIf cfg.amnezia.enable {
      programs.amnezia-vpn.enable = true;
      environment.systemPackages = [ pkgs.amneziawg-tools ];

      # Модуль nixpkgs включает systemd-resolved — Amnezia раздаёт DNS через
      # него. Без dnscrypt resolved остаётся единственным резолвером, поэтому
      # глушим то, что он делает по умолчанию: шлёт имена в локальную сеть
      # (LLMNR, mDNS) и, не зная DNS, уходит на запасные Google и Cloudflare.
      services.resolved.settings.Resolve = {
        LLMNR = false;
        MulticastDNS = false;
        FallbackDNS = "";
      };
    })

    (lib.mkIf cfg.wireguard.enable {
      environment.systemPackages = [ pkgs.wireguard-tools ];
    })

    (lib.mkIf cfg.throne.enable {
      programs.throne = {
        enable = true;
        tunMode.enable = cfg.throne.tun;
      };
    })

    (lib.mkIf cfg.byedpi.enable {
      services.byedpi = {
        enable = true;
        # Без -i он слушал бы все адреса: фаервол бы закрыл, но незачем.
        extraArgs = [
          "-i"
          "127.0.0.1"
          "-p"
          "1080"
        ]
        ++ cfg.byedpi.args;
      };
    })

    (lib.mkIf cfg.tor.enable {
      services.tor = {
        enable = true;
        client.enable = true; # SOCKS на 127.0.0.1:9050
        settings = lib.mkIf (cfg.tor.bridges != [ ]) {
          UseBridges = true;
          Bridge = cfg.tor.bridges;
          ClientTransportPlugin = [
            "obfs4,webtunnel exec ${lib.getExe pkgs.lyrebird}"
            "snowflake exec ${lib.getExe' pkgs.snowflake "client"}"
          ];
        };
      };
    })
  ];
}
