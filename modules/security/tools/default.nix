# Инструменты: песочницы, аудит и резервные копии того, без чего диск не
# открыть и не загрузить.
{ pkgs, ... }:

let
  script =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./${name}.sh;
    };
in
{
  # Как инструмент. Браузер им не оборачивать: helium уже живёт в bubblewrap,
  # а firejail поверх режет user namespaces, без которых тот не стартует.
  programs.firejail.enable = true;

  environment.systemPackages = with pkgs; [
    bubblewrap
    clamav
    lynis

    (script "secureboot-backup" [
      coreutils
      gnupg
      gnutar
    ])
    (script "luks-header-backup" [
      coreutils
      cryptsetup
      gnugrep
      gnupg
      util-linux
    ])
  ];
}
