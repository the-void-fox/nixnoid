# Bash: темы, алиасы и `bash-theme`. Тема — каталог в ./themes:
#   theme.sh      промпт, приветствие и реакция на неизвестную команду
#   issue         баннер на текстовой консоли
#   sudo-lecture  что показывает sudo перед паролем
{
  config,
  lib,
  pkgs,
  ...
}:

let
  themes = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./themes));
  theme = ./themes/${config.custom.shell.theme};
in
{
  options.custom.shell.theme = lib.mkOption {
    type = lib.types.enum themes;
    default = "minimal";
    description = "Тема bash. Доступны: ${lib.concatStringsSep ", " themes}.";
  };

  config = {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "bash-theme";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          gnused
        ];
        runtimeEnv = {
          PANEL = "${config.custom.repo}/configuration.nix";
          AVAILABLE = themes;
          CURRENT = config.custom.shell.theme;
        };
        text = builtins.readFile ../system/rebuild/ui.sh + builtins.readFile ./bash-theme.sh;
      })
    ];

    programs.bash = {
      completion.enable = true;
      promptInit = builtins.readFile (theme + "/theme.sh");
    };

    # Общее для всех тем; подключается после темы.
    environment.interactiveShellInit = builtins.readFile ./interactive.sh;

    environment.etc = {
      issue.source = theme + "/issue";
      sudo-lecture.source = theme + "/sudo-lecture";
    };

    environment.variables = {
      HISTSIZE = "10000";
      HISTFILESIZE = "20000";
      HISTCONTROL = "ignoreboth:erasedups";
    };

    environment.shellAliases = {
      themes = "bash-theme list";

      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first --git";
      lt = "eza --tree --level=2 --icons";
      cat = "bat --style=auto";
      cp = "xcp";
      df = "duf";
      ps = "procs";
      dig = "doggo";
      lsusb = "cyme";
      rm = "rm -i";
      mv = "mv -i";
      ff = "fd --type f";

      ".." = "cd ..";
      "..." = "cd ../..";
      ".3" = "cd ../../..";
      c = "clear";

      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate -15";
      gd = "git diff";

      ports = "sudo ss -tulnp";
      meminfo = "free -h";
      cpuinfo = "lscpu | head -20";
      syslog = "journalctl -xe --no-pager | tail -50";
      services = "systemctl list-units --type=service --state=running";

      nix-installed = "nix-store -qR /run/current-system | wc -l";
      nix-size = "nix path-info -Sh /run/current-system";
      nix-gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    };
  };
}
