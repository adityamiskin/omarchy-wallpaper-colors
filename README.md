# Wallpaper Colors

Recolors your current Omarchy theme from the wallpaper. Change the wallpaper and the bar, menus, borders, terminals, browser, and editors follow it. Your theme stays active; only its colors change.

- **Light or dark by image.** Bright wallpapers (mean brightness above 0.6) get a light palette, everything else a dark one.
- **Calm backgrounds.** Backgrounds keep the wallpaper's hue at half strength, so they read as dark (or light) first and tinted second.
- **Readable terminals.** ANSI colors start at their usual hues, lean up to 15° toward the wallpaper, and are then pushed to at least 4.5:1 contrast against the background. Text gets 7:1.
- **Pick the accent.** The palette icon in the bar lists the accents the wallpaper's colors produce. Picking one rebuilds the palette around it and is remembered for that wallpaper.
- **Theme default.** The same popup puts the theme's own colors back and stops recoloring that theme until you pick a color again.

## Install

Needs [matugen](https://github.com/InioX/matugen), from the Arch `extra` repository.

```bash
omarchy plugin add https://github.com/adityamiskin/omarchy-wallpaper-colors.git --enable
```

Then add the **Wallpaper Colors** widget to the bar for the accent picker.

## What it changes

| Path | What |
| --- | --- |
| `~/.config/omarchy/themes/<theme>/colors.toml` | Omarchy's per-theme color override, for the theme you are using. Its first line says the plugin wrote it. |
| `~/.local/state/omarchy/wallpaper-colors/` | Accent picks per wallpaper, themes set to Theme default, and backups |

If you already had your own `colors.toml` for that theme, it is backed up first and restored by Theme default. Themes installed from git are left alone, since changing their files would conflict with `omarchy theme update`.

Only `colors.toml` is overridden. Files a theme ships for a specific app, such as `neovim.lua` or `vscode.json`, keep the theme's own colors.

## How it works

The service polls the wallpaper link every 1.5s (Omarchy has no hook for wallpaper changes) and runs `bin/wallpaper-colors sync` when it moves. That writes the theme's `colors.toml` from matugen's palette via `bin/colors.jq` and reapplies the same theme without touching the wallpaper. A sync that would produce identical colors is skipped, since every theme change briefly stalls input while apps retint.

```bash
bin/wallpaper-colors sync          # recolor the current theme from the wallpaper
bin/wallpaper-colors sources       # accents available for the current wallpaper (JSON)
bin/wallpaper-colors pick <index>  # use that accent for this wallpaper (0 = default)
bin/wallpaper-colors reset         # Theme default for the current theme
```

## Uninstall

Choose **Theme default** on each theme you used it with, then:

```bash
omarchy plugin remove adityamiskin.wallpaper-colors
rm -rf ~/.local/state/omarchy/wallpaper-colors
```

## Credits

The ANSI color approach comes from [omawall](https://github.com/matjam/omawall). The accent popup and the per-theme override approach are modeled on [accent-picker](https://github.com/worstpoetGIT/accent-picker).

## License

MIT
