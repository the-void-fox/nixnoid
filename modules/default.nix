# Каталог — область системы. Его default.nix перечисляет файлы области и
# держит то немногое, что не тянет на отдельный файл.
{
  imports = [
    ./system
    ./hardware
    ./security
    ./desktop
    ./apps
    ./shell
  ];
}
