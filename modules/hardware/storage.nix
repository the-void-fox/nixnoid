# Единственный системный диск — SATA SSD за USB-мостом (Silicon Power PC60),
# под LUKS. Если система «тормозит, а процессор простаивает», сначала `diag`:
#   • USB 2 (480 Мбит/с) вместо USB 3 — диск в сорок раз медленнее, и никакой
#     тюнинг ниже этого не компенсирует;
#   • TRIM этот мост не пропускает: контроллер не знает о свободных блоках и
#     со временем деградирует. Лечится только разом — диск на настоящий SATA
#     (или мост ASM1351 / JMS578) и `sudo fstrim -av`. Пустое место помогает
#     лишь отсрочить это.
{ pkgs, ... }:

{
  # Пока мост TRIM не пропускает, обе настройки бездействуют. Но удалишь их —
  # и TRIM молча не заработает даже на правильном железе.
  # (Цена allowDiscards: снаружи видно, какие блоки заняты.)
  boot.initrd.luks.devices."luks-1838232e-2e22-4883-9f75-963db471c501" = {
    allowDiscards = true;
    bypassWorkqueues = true; # без рабочих очередей dm-crypt — меньше задержек
  };
  services.fstrim.enable = true;

  fileSystems."/".options = [
    "noatime" # меньше мелких записей; один ext4 на всё
    # Прошивка SSD врёт про optimal_io_size (32 МБ), mkfs поверил и записал
    # в суперблок полосу 32 МБ, а ext4 по ней раздувал упреждающее чтение
    # до 64 МБ. stripe=0 убирает причину, правило udev ниже — следствие.
    "stripe=0"
  ];

  services.udev.extraRules = ''
    # BFQ — только вращающемуся диску: делит головку между процессами честно.
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    # SSD головку беречь не надо, BFQ там лишь добавил бы задержку.
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"

    # Упреждающее чтение — как у обычного диска. Проверка: diag.
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/read_ahead_kb}="256"
    ACTION=="add|change", KERNEL=="dm-[0-9]*", ATTR{queue/read_ahead_kb}="256"
  '';

  boot.kernelModules = [
    "bfq"
    # Файловые системы внешних носителей.
    "ntfs3"
    "isofs"
  ];

  boot.kernel.sysctl = {
    # Не копить гигабайты «грязных» страниц: запись идёт ровно, без залпов,
    # которые насыщают диск и вешают чтение (это и было замиранием десктопа
    # при распаковке игр).
    "vm.dirty_bytes" = 268435456; # 256 МиБ
    "vm.dirty_background_bytes" = 134217728; # 128 МиБ
    "vm.dirty_writeback_centisecs" = 1500;

    # Своп теперь только zram, то есть сжатие в памяти, а не запись на диск.
    # Значит, лучше сжать простаивающую память, чем выкинуть кэш файлов и потом
    # перечитывать их с медленного SSD. Так советуют для zram Fedora и Pop!_OS.
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0; # упреждающее чтение из zram только тратит процессор
    "vm.vfs_cache_pressure" = 50;
  };

  # ~7,8 ГиБ сжатого свопа в памяти. Дискового свопа нет намеренно: он писал
  # бы на тот самый USB-SSD без TRIM, а сброс моста во время обращения к свопу
  # вешает систему. Нужна гибернация — своп-файл на внутренний диск машины.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # tmpfs занимает столько, сколько в него записали; 50% — потолок, а не
  # резерв. Сборки nix сюда не ходят (system/nix.nix).
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";
  };

  # SMART через USB-мост — только с `-d sat`: sudo smartctl -d sat -a /dev/sdb
  # Смотреть Temperature_Celsius (перегрев даёт троттлинг), Total_LBAs_Written,
  # Wear_Leveling_Count, Available_Reserved_Space.
  environment.systemPackages = [ pkgs.smartmontools ];
}
