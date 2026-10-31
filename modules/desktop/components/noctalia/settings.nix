# Настройки noctalia — только то, что отличается от её умолчаний
# (Assets/settings-default.json в исходниках). Чего здесь нет, noctalia
# подставит сама.
{ home, terminal }:

{
  bar = {
    backgroundOpacity = 1;

    # Раскладка панели целиком: сессии дописывают сюда свои виджеты
    # (mango ставит в начало правой части индикатор раскладки окон).
    widgets = {
      left = [
        { id = "Launcher"; }
        { id = "Clock"; }
        { id = "SystemMonitor"; }
        { id = "ActiveWindow"; }
        { id = "MediaMini"; }
      ];
      center = [ { id = "Workspace"; } ];
      right = [
        { id = "Tray"; }
        { id = "NotificationHistory"; }
        { id = "Battery"; }
        { id = "Volume"; }
        { id = "Brightness"; }
        { id = "ControlCenter"; }
      ];
    };
  };

  general = {
    enableShadows = false;
    enableBlurBehind = false;
    forceBlackScreenCorners = true;
  };

  ui = {
    fontDefault = "Arial";
    panelBackgroundOpacity = 1;
  };

  colorSchemes.predefinedScheme = "Monochrome";

  wallpaper = {
    directory = "${home}/.local/share/backgrounds";
    solidColor = "#000000";
  };

  appLauncher = {
    enableClipboardHistory = true;
    terminalCommand = "${terminal} -e";
  };

  brightness.enableDdcSupport = true; # внешние мониторы — через ddcutil

  # Без гибернации: protectKernelImage добавляет в cmdline nohibernate, и
  # кнопка молча ничего бы не делала. Список целиком — он заменяет умолчание.
  sessionMenu.powerOptions = [
    {
      action = "lock";
      enabled = true;
      keybind = "1";
    }
    {
      action = "suspend";
      enabled = true;
      keybind = "2";
    }
    {
      action = "hibernate";
      enabled = false;
      keybind = "3";
    }
    {
      action = "reboot";
      enabled = true;
      keybind = "4";
    }
    {
      action = "logout";
      enabled = true;
      keybind = "5";
    }
    {
      action = "shutdown";
      enabled = true;
      keybind = "6";
    }
    {
      action = "rebootToUefi";
      enabled = true;
      keybind = "7";
    }
  ];
}
