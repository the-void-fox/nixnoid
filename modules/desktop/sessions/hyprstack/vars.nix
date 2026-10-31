# Переменные hyprstack (~/.config/hyprstack/hypr-vars.lua) — поверх его
# config/variables.lua, где лежит полный список имён. Грузятся ДО
# keybinds.lua, поэтому переназначения штатных действий живут здесь, а то,
# для чего переменной нет, — в extra.lua.
{ apps, cursor }:

{
  # Вместо умолчаний hyprstack: kitty, firefox, xdg-open.
  terminal = apps.terminal.command;
  browser = apps.browser.command;
  fileExplorer = apps.fileManager.command;
  editor = "codium";

  # hyprstack сам выставляет XCURSOR_* (env.lua), по умолчанию — Adwaita.
  cursorTheme = cursor.name;
  cursorSize = cursor.size;

  # ── Приложения и спецстолы — на Super+Alt ──────────────────────────────────
  # Одиночные Super+буква отданы окнам, как в niri; Super+Alt+буква жмётся
  # одной левой.
  kbBrowser = "SUPER + ALT + W"; # было SUPER + W — в niri это табы
  kbEditor = "SUPER + ALT + C"; # было SUPER + C — в niri это центровка
  kbFileExplorer = "SUPER + ALT + E";
  kbSpecialWs = "SUPER + ALT + S"; # было SUPER + S — в niri это скриншот
  kbTodoWs = "SUPER + ALT + T"; # было SUPER + R — в niri это ширина колонки
  kbMusicWs = "SUPER + ALT + M";
  kbMoveWinToWsSpecial = "CTRL + SUPER + SHIFT + Up"; # освобождает SUPER + ALT + S

  # ── Окна — как в niri ──────────────────────────────────────────────────────
  kbWindowBorderedFullscreen = "SUPER + F"; # maximize-column
  kbWindowFullscreen = "SUPER + SHIFT + F"; # fullscreen-window
  kbCenterWindow = "SUPER + C"; # center-column
  kbToggleWindowFloating = "SUPER + ALT + V";
  kbScreenshotRegion = "SUPER + S";

  # ── Разгрузка неудобных сочетаний ──────────────────────────────────────────
  kbClipboardDel = "CTRL + SUPER + V";
  kbClipboardPasteLatest = "SUPER + SHIFT + V";
  kbNormalizeWindow = "CTRL + SUPER + Backslash"; # было CTRL + SUPER + ALT + Backslash
  # SUPER + SHIFT + L занимает layouts.lua («поменять колонку») уже после
  # keybinds.lua: на штатном бинде засыпание молча терялось.
  kbSleep = "CTRL + SUPER + SHIFT + L";
  # SUPER + U — стол ниже, как в niri (extra.lua).
  kbUngroup = "CTRL + SUPER + U";
}
