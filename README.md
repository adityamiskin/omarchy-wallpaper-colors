# Wallpaper Colors

Your wallpaper is your theme. Change the wallpaper and the whole Omarchy desktop recolors from it: bar, menus, borders, terminals, browser, and editors.

- **Light or dark by image.** Bright wallpapers (mean brightness above 0.6) get a light theme, everything else a dark one.
- **Calm backgrounds.** Backgrounds keep the wallpaper's hue at half strength, so they read as dark (or light) first and tinted second.
- **Readable terminals.** ANSI colors start at their usual hues, lean up to 15° toward the wallpaper, and are then pushed to at least 4.5:1 contrast against the background. Text gets 7:1.
- **Pick the accent.** The palette icon in the bar lists the accents the wallpaper's colors produce. Picking one rebuilds the palette around it and is remembered for that wallpaper.
- **One picker.** Every wallpaper from every theme shows up in the background picker. Drop your own into `~/.config/omarchy/backgrounds/wallpaper/` and they appear immediately.

## Install

Needs [matugen](https://github.com/InioX/matugen):

```bash
sudo pacman -S matugen
omarchy plugin add https://github.com/adityamiskin/omarchy-wallpaper-colors.git --enable
```

Then add the **Wallpaper Colors** widget to the bar if you want the accent picker.

## What it changes

Enabling the plugin switches you to a generated `wallpaper` theme and keeps it in sync with the wallpaper. It writes only these:

| Path | What |
| --- | --- |
| `~/.config/omarchy/themes/wallpaper/` | The generated theme |
| `~/.config/omarchy/backgrounds/wallpaper/` | Links to every installed wallpaper, for the picker |
| `~/.local/state/omarchy/wallpaper-colors/` | Accent picks and the last applied wallpaper |

## How it works

The service polls the wallpaper link every 1.5s (Omarchy has no hook for wallpaper changes) and runs `bin/wallpaper-colors sync` when it moves. That writes `~/.config/omarchy/themes/wallpaper/colors.toml` from matugen's palette via `bin/colors.jq` and applies the `wallpaper` theme without touching the wallpaper. A sync that would produce identical colors is skipped, since every theme change briefly stalls input while apps retint.

Picking a regular theme still works until the next wallpaper change.

```bash
bin/wallpaper-colors sync          # recolor from the current wallpaper
bin/wallpaper-colors sources       # accents available for the current wallpaper (JSON)
bin/wallpaper-colors pick <index>  # use that accent for this wallpaper (0 = default)
```

State lives in `~/.local/state/omarchy/wallpaper-colors/`.

## Uninstall

```bash
omarchy plugin remove adityamiskin.wallpaper-colors
omarchy theme set tokyo-night
rm -rf ~/.config/omarchy/themes/wallpaper ~/.config/omarchy/backgrounds/wallpaper ~/.local/state/omarchy/wallpaper-colors
```

## Credits

The ANSI color approach comes from [omawall](https://github.com/matjam/omawall). The accent popup is modeled on [accent-picker](https://github.com/worstpoetGIT/accent-picker).

## License

MIT
