# Система живёт на съёмном SSD и должна подниматься на ЛЮБОЙ машине: initrd
# обязан найти корень и принять пароль LUKS при любом чипсете.
#
# Список нарочно широкий и складывается с hardware-configuration.nix.
# «available» значит «положить в initrd»: грузит модуль udev, и только если
# такое железо есть, так что лишние ничему не мешают.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    # USB-контроллеры всех поколений
    "xhci_pci"
    "xhci_hcd"
    "ehci_pci"
    "ehci_hcd"
    "ohci_pci"
    "ohci_hcd"
    "uhci_hcd"

    # USB-накопители и клавиатура — для пароля LUKS
    "usb_storage"
    "uas"
    "usbhid"
    "hid_generic"

    # Встроенная клавиатура ноутбука (PS/2)
    "atkbd"
    "i8042"
    "libps2"
    "serio_raw"

    # SATA / AHCI / старый IDE
    "ahci"
    "ata_piix"
    "ata_generic"
    "pata_acpi"
    "sata_nv"
    "sata_sis"
    "sata_via"
    "sd_mod"
    "sr_mod"

    "nvme"

    # SD / eMMC: ноутбуки и картридеры
    "sdhci"
    "sdhci_pci"
    "sdhci_acpi"
    "mmc_block"
    "rtsx_pci"
    "rtsx_pci_sdmmc"
    "rtsx_usb"
    "rtsx_usb_sdmmc"

    # Виртуальные машины: QEMU, VMware, Hyper-V
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "vmw_pvscsi"
    "hv_storvsc"
  ];

  # Микрокод обоих вендоров: под диском может оказаться и Intel, и AMD.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  # kvm-amd сюда НЕ добавлять: на Intel он падает при загрузке с «CPU isn't
  # AMD or Hygon». kvm-intel задан в hardware-configuration.nix; для AMD-машины
  # его надо перегенерировать.
}
