# Видео. Основа — AMD (десктоп). У ноутбука-Optimus (Intel UHD 630 +
# GTX 1050 Ti) свой пункт загрузчика «nixos (nvidia)».
{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu.opencl.enable = true;
  environment.variables.RUSTICL_ENABLE = "radeonsi";

  # Без явного драйвера libva иногда промахивается и тихо декодирует видео
  # процессором. Проверка: `vainfo` — должны быть VAProfileH264 и VAProfileAV1.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";
  environment.systemPackages = [ pkgs.libva-utils ];

  boot.kernelParams = [
    "amdgpu.dc=1"
    "amdgpu.gpu_recovery=1"
    "amdgpu.dcdebugmask=0x10"
    "amdgpu.runpm=0"
  ];

  # nouveau на Pascal сыпет GPU-фолтами и превращает картинку в кашу. Без него
  # обычная загрузка на любой машине идёт на встроенной графике.
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Проприетарный драйвер — только в своём пункте загрузчика, чтобы общий с
  # AMD конфиг его не видел. Тяжёлое приложение — через `nvidia-offload <app>`.
  specialisation.nvidia.configuration = {
    system.nixos.tags = [ "nvidia" ];

    # Модуль Nvidia собран вне ядра и не подписан: при sig_enforce=1 ядро его
    # не загрузит. Выбирая этот пункт, соглашаешься на неподписанный модуль.
    custom.hardening.signedModulesOnly = false;

    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true; # обязателен для Wayland
      open = false; # Pascal открытый модуль не поддерживает
      nvidiaSettings = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:0:2:0"; # Intel UHD 630
        nvidiaBusId = "PCI:1:0:0"; # GTX 1050 Ti
      };
    };
  };
}
