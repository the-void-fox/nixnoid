{
  config,
  inputs,
  lib,
  ...
}:

let
  user = config.custom.user;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options = {
    custom.user = lib.mkOption {
      type = lib.types.str;
      description = "Единственный пользователь системы.";
    };

    # Короткий путь к home-manager этого пользователя: модули пишут
    # `hm.xdg.configFile…`, а не `home-manager.users.<имя>.xdg.configFile…`.
    hm = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = "Модуль home-manager для {option}`custom.user`.";
    };
  };

  config = {
    users = {
      # Учётки — только из конфига. Пароль лежит вне репозитория.
      mutableUsers = false;
      users.root.hashedPassword = "!"; # вход под root закрыт

      users.${user} = {
        isNormalUser = true;
        description = "VoidFox";
        hashedPasswordFile = "/persist/secrets/${user}-password";
        homeMode = "700";
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "lp"
          "i2c"
        ];
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${user} = config.hm;
    };

    hm.home = {
      username = user;
      homeDirectory = "/home/${user}";
      stateVersion = "26.05"; # отметка подключения home-manager, тоже не менять
    };
  };
}
