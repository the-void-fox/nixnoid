{
  imports = [
    ./audio.nix
    ./gpu.nix
    ./peripherals.nix
    ./portable.nix
    ./storage.nix
  ];

  hardware.enableAllFirmware = true;

  # Игровой десктоп без батареи: держим частоты, а не экономим.
  powerManagement.cpuFreqGovernor = "performance";

  # Иначе прерывания от диска и сети оседают на нулевом ядре — ровно тогда,
  # когда всё и так занято.
  services.irqbalance.enable = true;
}
