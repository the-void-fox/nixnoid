# `diag` — состояние системы одним текстом: проще переслать, чем объяснять.
#   diag              на экран
#   diag > ~/diag.txt в файл
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "diag";
      runtimeInputs = with pkgs; [
        procps # uptime -p; должен идти раньше coreutils
        coreutils
        findutils
        gawk
        gnugrep
        gnused
        iproute2
        libva-utils
        pciutils
        systemd
        util-linux
        wireplumber
      ];
      # Без errexit: одна неудачная проверка не должна обрывать весь отчёт.
      bashOptions = [ ];
      text = builtins.readFile ./diag.sh;
    })
  ];
}
