# Maps `matugen image --json hex` output onto an Omarchy colors.toml. Args: $mode ("dark" | "light").

def tone(p; t): .palettes[p][t].color;
def mod($n): . - $n * (. / $n | floor);
def clamp($lo; $hi): [[., $lo] | max, $hi] | min;
def rgb: ltrimstr("#") | [range(0; 6; 2) as $i | .[$i:$i + 2] | explode | map(if . > 96 then . - 87 else . - 48 end) | (.[0] * 16 + .[1]) / 255];
def hsl:
  rgb | (max - min) as $d | ((max + min) / 2) as $l | . as [$r, $g, $b]
  | [(if $d == 0 then 0 elif max == $r then ($g - $b) / $d elif max == $g then ($b - $r) / $d + 2 else ($r - $g) / $d + 4 end * 60 | mod(360)),
     (if $d == 0 then 0 else $d / (1 - (2 * $l - 1 | fabs)) end), $l];
def hex:
  . as [$h, $s, $l] | ($s * ([$l, 1 - $l] | min)) as $a
  | [(0, 8, 4) | (. + $h / 30 | mod(12)) as $k | $l - $a * ([$k - 3, 9 - $k, 1] | min | clamp(-1; 1)) | . * 255 | round]
  | "#" + (map("0123456789abcdef" as $x | $x[. / 16 | floor:(. / 16 | floor) + 1] + $x[mod(16):mod(16) + 1]) | join(""));
def luminance: rgb | map(if . <= 0.04045 then . / 12.92 else (. + 0.055) / 1.055 | pow(.; 2.4) end) | .[0] * 0.2126 + .[1] * 0.7152 + .[2] * 0.0722;
def contrast($other): [luminance, ($other | luminance)] | sort | (.[1] + 0.05) / (.[0] + 0.05);

# Walks lightness away from $bg until the color reaches the WCAG ratio, so a muddy wallpaper can't
# produce unreadable text.
def readable($bg; $ratio):
  if contrast($bg) >= $ratio then . else
    hsl as [$h, $s, $l] | (if ($bg | luminance) > 0.18 then -0.02 else 0.02 end) as $step
    | first(range(1; 50) | [$h, $s, ($l + . * $step | clamp(0; 1))] | hex | select(contrast($bg) >= $ratio))
      // (if $step < 0 then "#000000" else "#ffffff" end)
  end;

# Backgrounds keep the wallpaper hue at half its tint; full strength reads as a colored wash.
def surface(t): tone("neutral_variant"; t) | hsl | .[1] *= 0.5 | hex;

. as $m
| (if $mode == "light" then {
    background: surface("95"),
    dark_background: surface("90"),
    darker_background: surface("80"),
    lighter_background: surface("90"),
    foreground: tone("neutral"; "10"),
    light_foreground: tone("neutral"; "25"),
    bright_foreground: "#000000",
    dark_foreground: tone("neutral_variant"; "50"),
    selection: tone("primary"; "90"),
    muted: tone("neutral_variant"; "70")
  } else {
    background: surface("10"),
    dark_background: surface("5"),
    darker_background: "#000000",
    lighter_background: surface("15"),
    foreground: tone("neutral"; "90"),
    light_foreground: tone("neutral"; "95"),
    bright_foreground: "#ffffff",
    dark_foreground: tone("neutral_variant"; "60"),
    selection: tone("primary"; "30"),
    muted: tone("neutral_variant"; "40")
  } end) as $base
| $base.background as $bg

# After omawall: canonical ANSI hues nudged up to 15° toward the wallpaper, at its saturation.
| ($m.colors.source_color[$mode].color | hsl) as [$hue, $sat]
| ($sat * 0.9 + 0.15 | clamp(0.42; 0.78)) as $sat
| (if $mode == "dark" then [0.70, 0.77, 1.08] else [0.42, 0.34, 1.12] end) as [$lit, $brightlit, $brightsat]
| {red: [2, 1, 1], orange: [28, 1, 1.02], yellow: [48, 1, 1.05], green: [122, 0.92, 1],
   cyan: [186, 0.95, 0.98], blue: [218, 1, 0.98], magenta: [292, 0.95, 1]}
| with_entries(.value as [$h, $s, $l]
    | ($hue - $h + 540 | mod(360) - 180 | . * 0.15 | clamp(-15; 15) | . + $h | mod(360)) as $h
    | [{key, value: [$h, $s * $sat, ($lit * $l | clamp(0.05; 0.95))] | hex | readable($bg; 4.5)},
       {key: "bright_\(.key)", value: [$h, ($s * $sat * $brightsat | clamp(0; 1)), ($brightlit * $l | clamp(0.05; 0.95))] | hex | readable($bg; 4.5)}][])
  as $ansi

| {mode: $mode, accent: ($m.colors.primary[$mode].color | readable($bg; 3))}
  + $base
  + {foreground: ($base.foreground | readable($bg; 7)), dark_foreground: ($base.dark_foreground | readable($bg; 3))}
  + $ansi
| to_entries[] | "\(.key) = \"\(.value)\""
