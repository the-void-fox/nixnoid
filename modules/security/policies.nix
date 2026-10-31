# Кто и что может: sudo, polkit, PAM, AppArmor и мелкие запреты.
{ lib, ... }:

{
  security = {
    apparmor = {
      enable = true;
      # При загрузке профилей убивает процессы, которые успели стартовать без
      # них. В теории может прибить что-то посреди rebuild; на практике ни разу.
      killUnconfinedConfinables = true;
    };

    sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = always
        Defaults lecture_file = /etc/sudo-lecture
        Defaults timestamp_timeout = 5
        Defaults logfile = /var/log/sudo.log

        # Команда в отдельном pty: процесс не впишет ввод в родительский
        # терминал после выхода из sudo. С 1.9.14 это и так по умолчанию —
        # строка держит защиту, если умолчание когда-нибудь поменяется.
        Defaults use_pty

        # log_input/log_output не включать: они без ротации пишут весь ввод,
        # включая пароли в интерактивных программах, открытым текстом.
      '';
    };

    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.freedesktop") === 0) {
            polkit.log("Action: " + action.id + " by " + subject.user);
          }
        });
      '';
    };

    pam = {
      # Четыре секунды за каждую неверную попытку пароля.
      services = {
        login.failDelay = {
          enable = true;
          delay = 4000000;
        };
        sudo.failDelay = {
          enable = true;
          delay = 4000000;
        };
      };

      loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "core";
          value = "0";
        }
        {
          domain = "*";
          type = "soft";
          item = "nproc";
          value = "10000";
        }
        {
          domain = "*";
          type = "hard";
          item = "nproc";
          value = "20000";
        }
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "524288";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
      ];
    };

    chromiumSuidSandbox.enable = true; # песочница браузеров на Chromium
  };

  systemd.coredump.enable = false;

  # Геолокация никому не нужна, хотя модули рабочих столов её включают.
  services.geoclue2.enable = lib.mkForce false;

  # Две консоли вместо шести.
  services.logind.settings.Login = {
    NAutoVTs = 2;
    ReserveVT = 2;
  };
}
