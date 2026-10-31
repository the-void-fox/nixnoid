# Программы — по назначению, а не по источнику: nixpkgs, flatpak и входы
# флейка лежат вместе, в файле той задачи, для которой нужны.
#
# environment.systemPackages — инструменты: консольные утилиты (их видят root
# и глобальные алиасы) и то, что встраивается в систему. Приложения —
# в профиле пользователя, hm.home.packages.
{ inputs, ... }:

{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./ai.nix
    ./dev.nix
    ./files.nix
    ./games.nix
    ./media.nix
    ./social.nix
    ./tools.nix
    ./votv
  ];

  services.flatpak = {
    enable = true;
    packages = [ "com.github.tchx84.Flatseal" ]; # права flatpak-приложений
  };

  # AppImage — через appimage-run, а не запуском напрямую (binfmt).
  programs.appimage = {
    enable = true;
    binfmt = false;
  };
}
