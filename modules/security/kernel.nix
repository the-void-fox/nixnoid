# Укрепление ядра: параметры загрузки, sysctl и запрет ненужных модулей.
{ config, lib, ... }:

{
  options.custom.hardening.signedModulesOnly = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Требовать подпись модулей ядра (`module.sig_enforce=1`) и держать
      `lockdown=integrity`.

      Выключено: начиная с ядра 7.3 модули в nixpkgs подписаны ключом,
      которому ядро не доверяет (у всех `/sys/module/*/taint` = E), и с этим
      флагом система не грузится вовсе — initrd не поднимает даже dm_crypt.
      Включать снова, только проверив `cat /sys/module/ext4/taint` на новом ядре.

      Специализация nvidia выключает флаг в любом случае: проприетарный модуль
      собран вне ядра и не подписан.
    '';
  };

  config = {
    security.protectKernelImage = true;

    boot.kernelParams = [
      "randomize_kstack_offset=on"
      "page_alloc.shuffle=1"
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "debugfs=off"
      "vsyscall=emulate"

      # spectre_v2=on не ставим: на этих Intel он навязывает retpoline, и
      # RETBleed остаётся открытым. Ядро само выбирает IBRS — он закрывает оба.
      "spec_store_bypass_disable=on"
      "l1tf=full,force"
      "kvm.nx_huge_pages=force"

      # DMA: устройствам нельзя ходить мимо IOMMU (passthrough=0), а IOTLB
      # сбрасывается сразу (strict=1). Устаревший iommu=force не нужен — его
      # к тому же подозревали в зависании на финальной фазе выключения.
      "intel_iommu=on"
      "iommu.passthrough=0"
      "iommu.strict=1"
      "efi=disable_early_pci_dma"

      # oops=panic и panic=1 не ставим: на чужом железе любой некритичный oops
      # превращался в цикл перезагрузок без диагностики и отнимал аварийный
      # выход через SysRq (ниже).
    ]
    ++ lib.optionals config.custom.hardening.signedModulesOnly [
      "lockdown=integrity"
      "module.sig_enforce=1"
    ];

    boot.kernel.sysctl = {
      # ── Сеть ── (rp_filter задан в system/networking.nix: его диктует tailscale)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_max_syn_backlog" = 2048;
      "net.ipv4.tcp_synack_retries" = 2;

      # ── Ядро ──
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.perf_event_paranoid" = 3;

      # SysRq: 16 sync + 32 remount ro + 128 reboot/poweroff. При зависании —
      # Alt+SysRq+S, U, O вместо срыва питания на ext4 поверх LUKS. Дампы (8) и
      # сигналы процессам (64) не даём.
      "kernel.sysrq" = 176;

      # ── Файлы и память ──
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "vm.mmap_rnd_bits" = 28;
      "vm.mmap_rnd_compat_bits" = 16;
    };

    boot.blacklistedKernelModules = [
      # Заброшенные файловые системы. squashfs здесь нет намеренно: на нём
      # живут AppImage, и это живой, сопровождаемый драйвер.
      "cramfs"
      "freevxfs"
      "jffs2"
      "hfs"
      "hfsplus"
      "udf"

      # Редкие сетевые протоколы — лишняя поверхность атаки.
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "n-hdlc"
      "ax25"
      "netrom"
      "x25"
      "rose"
      "decnet"
      "econet"
      "af_802154"
      "ipx"
      "appletalk"
      "psnap"
      "p8023"
      "p8022"
      "can"
      "atm"

      # FireWire и Thunderbolt: прямой доступ к памяти через порт.
      "firewire-core"
      "firewire-ohci"
      "firewire-sbp2"
      "thunderbolt"
    ];
  };
}
