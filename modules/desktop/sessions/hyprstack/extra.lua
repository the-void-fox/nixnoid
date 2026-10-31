-- Hyprstack: то, для чего в hypr-vars нет переменной.
--
-- Порядок загрузки — поэтому hl.unbind здесь работает:
--   config/hyprland.lua  -> hypr-vars.lua, затем hyprland/keybinds.lua
--   hypr-user.lua        -> defaults/hypr-user.lua
--                             -> layouts.lua   (бинды скроллинг-раскладки)
--                             -> monitors.lua, local.lua
--                           -> ЭТОТ ФАЙЛ (programs.hyprstack.extraConfig)
-- Он идёт последним и перебивает даже жёстко прошитые бинды layouts.lua
-- (SUPER+H/J/K/L, SUPER+O, SUPER+G и другие).
--
-- Перед ним Nix вставляет переменные окружения и мониторы (default.nix).

local layouts = hyprstack_layouts -- таблица раскладки, её экспортирует layouts.lua

local function rebind(key, action, description, options)
    local opts = options or {}
    opts.description = description
    hl.unbind(key)
    hl.bind(key, action, opts)
end

----------------------------------------------------------------------
-- Клавиатура: русская раскладка
----------------------------------------------------------------------
-- Переключение — Caps Lock на уровне xkb, а не биндом Hyprland: так оно
-- работает и на экране блокировки, где бинды композитора молчат.
-- Цена: Caps Lock больше не переключает регистр.
hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:caps_toggle",
    },
})

----------------------------------------------------------------------
-- Колонки и столы: добор биндов niri
----------------------------------------------------------------------
-- Уже совпадает с niri без нашего участия (layouts.lua):
--   SUPER+H / SUPER+L              колонка влево / вправо
--   SUPER+J / SUPER+K              стол ниже / выше
--   SUPER+SHIFT+H / SUPER+SHIFT+L  поменять колонку местами
--   SUPER+1..9                     перейти на стол
--   SUPER+SHIFT+1..9               перенести окно на стол
--   SUPER+SHIFT+Left/Right         перенести окно на соседний монитор
--   SUPER+Minus / SUPER+Equal      ширина колонки
--   SUPER+колесо                   прокрутка столов

-- Без таблицы раскладки этот блок пропускаем, чтобы клавиатура выше
-- всё равно применилась.
if layouts then
    -- niri: Mod+W, табы в колонке. Ближайшее — scrolling/stacking: в stacking
    -- окна колонки лежат друг на друге. Дубль на SUPER+CTRL+SHIFT+M остаётся.
    rebind("SUPER + W", function() layouts.toggle() end,
        "Windows: Toggle scrolling or stacking")

    -- niri: Mod+R, ширина колонки по пресетам.
    rebind("SUPER + R", function() layouts.toggle_width() end,
        "Windows: Toggle column width")

    -- niri: Mod+WheelScrollLeft/Right. Вертикальное колесо с SUPER уже листает
    -- столы (layouts.lua), горизонтальное свободно.
    rebind("SUPER + mouse_left", function() layouts.focus_column(-1) end,
        "Windows: Focus column left")
    rebind("SUPER + mouse_right", function() layouts.focus_column(1) end,
        "Windows: Focus column right")

    -- niri: Mod+I — стол выше, Mod+U — ниже (дубли к K/J).
    rebind("SUPER + I", function() layouts.step(-1) end,
        "Workspaces: Previous workspace", { repeating = true })
    rebind("SUPER + U", function() layouts.step(1) end,
        "Workspaces: Next workspace", { repeating = true })

    ------------------------------------------------------------------
    -- Мониторы: фокус и перенос
    ------------------------------------------------------------------
    -- Стрелки CTRL+SUPER+Left/Right не трогаем — в hyprstack они листают столы.
    for _, item in ipairs({
        { "H", "left" }, { "L", "right" }, { "K", "up" }, { "J", "down" },
    }) do
        -- niri: Mod+Ctrl+H/J/K/L — фокус на монитор.
        rebind("CTRL + SUPER + " .. item[1],
            function() layouts.focus_other_monitor(item[2]) end,
            "Windows: Focus monitor " .. item[2])

        -- niri: Mod+Shift+Ctrl+H/J/K/L — окно на монитор. Короче, тремя
        -- клавишами: SUPER+SHIFT+Left/Right из layouts.lua.
        rebind("CTRL + SUPER + SHIFT + " .. item[1],
            function() layouts.move_monitor(item[2]) end,
            "Windows: Move window to monitor " .. item[2])
    end
end

-- niri: Mod+Tab — обзор. SUPER+O из layouts.lua тоже остаётся.
rebind("SUPER + Tab", hl.dsp.global("hyprstack:overview"),
    "Shell: Open overview")

----------------------------------------------------------------------
-- Сессия
----------------------------------------------------------------------
-- niri: Mod+Shift+P. Отдельного действия в hl.dsp нет.
rebind("SUPER + SHIFT + P", hl.dsp.exec_cmd("hyprctl dispatch dpms off"),
    "Session: Power off monitors")

-- niri: Mod+Shift+Q — выход. Здесь это меню сеанса, оно же на CTRL+ALT+Delete.
rebind("SUPER + SHIFT + Q", hl.dsp.global("hyprstack:session"),
    "Session: Open session menu")

-- niri: Mod+Shift+Slash — подсказка по клавишам. Здесь список биндов живёт
-- в разделе «Сочетания клавиш» дашборда.
rebind("SUPER + SHIFT + Slash", hl.dsp.global("hyprstack:dashboard"),
    "Shell: Open dashboard")
