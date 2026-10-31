# Палитра темы hyprstack → CSS для GTK: Nautilus и прочие GTK-окна в цвет
# оболочки. Берётся из того же JSON, что и сама оболочка, чтобы не разъехалось.
themeFile:

let
  dark = (builtins.fromJSON (builtins.readFile themeFile)).modes.dark;

  # В JSON hyprstack цвета без решётки ("121212"), CSS её требует.
  c = name: "#" + (dark.${name} or dark.roles.${name});

  # Промежуточные поверхности hyprstack вычисляет сам — mix(bg, fg, k) в
  # palette() из shell/assets/theme_manager.py, — в JSON их нет. Та же
  # лестница, посчитанная для bg = 121212, fg = e6e6e6.
  surface = {
    low = "#171717"; # k = 0.025
    mid = "#1c1c1c"; # k = 0.045
    high = "#202020"; # k = 0.065
    highest = "#242424"; # k = 0.085
    borders = "#3c3c3c"; # k = 0.20, outlineVariant
    outline = "#7c7c7c"; # legible(mix(bg, fg, .50), bg, 3)
  };
in
{
  # libadwaita тем не поддерживает, но читает именованные цвета — ими и
  # подгоняются GTK4-приложения. Диалог выбора файла рисует уже оболочка.
  gtk4 = ''
    @define-color window_bg_color ${c "background"};
    @define-color window_fg_color ${c "foreground"};
    @define-color view_bg_color ${c "background"};
    @define-color view_fg_color ${c "foreground"};
    @define-color headerbar_bg_color ${surface.mid};
    @define-color headerbar_fg_color ${c "foreground"};
    @define-color headerbar_border_color ${surface.borders};
    @define-color headerbar_backdrop_color ${c "background"};
    @define-color headerbar_shade_color rgba(0, 0, 0, 0.36);
    @define-color sidebar_bg_color ${surface.low};
    @define-color sidebar_fg_color ${c "foreground"};
    @define-color sidebar_backdrop_color ${c "background"};
    @define-color sidebar_shade_color rgba(0, 0, 0, 0.36);
    @define-color secondary_sidebar_bg_color ${surface.mid};
    @define-color secondary_sidebar_fg_color ${c "foreground"};
    @define-color card_bg_color ${surface.mid};
    @define-color card_fg_color ${c "foreground"};
    @define-color card_shade_color rgba(0, 0, 0, 0.36);
    @define-color dialog_bg_color ${surface.high};
    @define-color dialog_fg_color ${c "foreground"};
    @define-color popover_bg_color ${surface.high};
    @define-color popover_fg_color ${c "foreground"};
    @define-color thumbnail_bg_color ${surface.highest};
    @define-color thumbnail_fg_color ${c "foreground"};
    @define-color shade_color rgba(0, 0, 0, 0.36);
    @define-color scrollbar_outline_color rgba(0, 0, 0, 0.5);
    @define-color borders ${surface.borders};

    @define-color accent_bg_color ${c "accent"};
    @define-color accent_fg_color ${c "onPrimary"};
    @define-color accent_color ${c "accent"};

    @define-color destructive_bg_color ${c "error"};
    @define-color destructive_fg_color ${c "onError"};
    @define-color destructive_color ${c "error"};
    @define-color error_bg_color ${c "error"};
    @define-color error_fg_color ${c "onError"};
    @define-color error_color ${c "error"};

    @define-color success_bg_color ${c "success"};
    @define-color success_fg_color ${c "onSuccess"};
    @define-color success_color ${c "success"};

    @define-color warning_bg_color ${c "secondary"};
    @define-color warning_fg_color ${c "onSecondary"};
    @define-color warning_color ${c "secondary"};
  '';

  # GTK3 подгоняется хуже: часть цветов Adwaita считает ещё при сборке из
  # SCSS, и CSS до них не дотягивается. theme_* закрывают главное.
  gtk3 = ''
    @define-color theme_bg_color ${c "background"};
    @define-color theme_fg_color ${c "foreground"};
    @define-color theme_base_color ${surface.low};
    @define-color theme_text_color ${c "foreground"};
    @define-color theme_selected_bg_color ${c "accent"};
    @define-color theme_selected_fg_color ${c "onPrimary"};
    @define-color insensitive_bg_color ${surface.mid};
    @define-color insensitive_fg_color ${surface.outline};
    @define-color borders ${surface.borders};
  '';
}
