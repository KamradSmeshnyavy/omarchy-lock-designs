# Omarchy Lock Designs

[🇷🇺 Русский](README.ru.md)

22 designs for the [Omarchy](https://omarchy.org) lock screen. Authentication is untouched: password,
PAM and fingerprint are the stock `omarchy.lock` service — only the view is swapped.

![Designs](screenshots/designs.webp)

<!-- Demo video: repo-videos/omarchy-lock-designs.mp4 — drag it here when editing this file on GitHub -->

classic (stock), zen, dock, island, split, sheet, card, cinema, poster, editorial, analog, flip, ring,
calendar, terminal, neon, system, music, aurora, rain, constellation, dotmatrix, glyph, liquid. All of them take their colours and
font from the active Omarchy theme (`dotmatrix` uses its signature pure `#000000` bezel, `Doto` Bold LED clock,
`Space Mono` uppercase labels, circular LED password dots and `#d71921` failure state). `glyph` is the lock screen of
[glyph-rice](https://github.com/Nebelung-cloud/glyph-rice) (GPL-3.0): a full-width Doto clock, the wallpaper assembling
from dots in the look of `~/.config/omarchy/wallpaper-look.json`, the avatar in an LED ring, a password pill of dots with a
red caret, a wave over the dots while PAM checks and a shake on a wrong password. `liquid` follows the lock screen of
[Vitreus](https://github.com/natepayn3/Vitreus): the wallpaper blurs in (`liquidBlur`, 0–1), a glowing clock, a glass avatar
and password pill, every typed character a random shape of 16 (their `shapes.svg`, MIT; `"liquidShapes": "dots"` — plain
dots), a red flash and a shake on a wrong password.

## Install

```sh
omarchy plugin add https://github.com/KamradSmeshnyavy/omarchy-lock-designs --enable
omarchy restart shell
echo '{"design": "flip"}' > ~/.config/omarchy/lock-design.json
```

Preview a design without locking (Esc or click closes it):

```sh
omarchy-shell lock previewDesign flip
```

Back to the stock lock: `omarchy plugin enable omarchy.lock`.


## Requirements

Omarchy 4 (Quattro) with its shell. Tested on Omarchy 4.0.6 with Quickshell 0.3.2.

- Authentication is the stock Omarchy PAM flow — nothing extra to install.
- DOT-MATRIX designs use the fonts shipped with the [Customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) (Doto, Space Grotesk, Space Mono); without them they fall back to the Omarchy font.

## Uninstall

```sh
omarchy plugin enable omarchy.lock      # switch back to the stock one first
omarchy plugin remove kamradsmeshnyavy.lock
omarchy restart shell
```

Your settings stay in `~/.config/omarchy/lock-design.json` — delete them by hand if you don't need them.

## Safety

- `Service.qml` is the stock one with no changes to the auth logic. The edits are marked `// design:` —
  `LockView` is replaced with `LockHost` in two places, plus the `previewDesign` IPC and Esc to close a preview.
- A design sees exactly what the stock `LockView` sees: the state, and the typed text it hands back
  through the `submitPassword` signal.
- `LockHost` falls back to the stock `LockView` if a design fails to load, is not found, or doesn't
  register its password field within 0.5 s. You never end up on a screen without a password field.
- The clone inherits the `authentication` capability from `omarchy.lock`, so the shell isolates it the
  same way.
- If something breaks while locked: switch to a TTY (Ctrl+Alt+F3) and run
  `omarchy plugin enable omarchy.lock` or `loginctl unlock-session`.

## Settings — `~/.config/omarchy/lock-design.json`

The file is watched and applied immediately.

| Key | Default | |
|---|---|---|
| `design` | `classic` | design id |
| `clock24` | `true` | 24-hour clock |
| `showSeconds` | `false` | seconds |
| `showDate` | `true` | date |
| `wallpaperBlur` | `1` | wallpaper blur, 0–1 |
| `wallpaperDim` | `0` | wallpaper dim, 0–0.9 |
| `reduceMotion` | `false` | no animations (aurora, rain, the second hand) |
| `ownerMessage` | `Hello, $USER` | greeting (Russian: `Привет, $USER`) |
| `lang` | — | `en` / `ru`; otherwise `lang` from `~/.config/omarchy/customizer.json`, then `$LANG` |
| `avatar` | `~/.face` | avatar image; without one, the first letter of the user name |

## Your own design

`~/.config/omarchy/lock-designs/Mine.qml`, selected as `my:Mine.qml`:

```qml
import QtQuick
import "../plugins/kamradsmeshnyavy.lock/designs"

DesignBase {
  id: root
  field: pw                       // required, otherwise the stock view is shown
  Wallpaper { anchors.fill: parent; host: root }
  Text { text: root.time; color: root.fg; font.family: root.font; font.pixelSize: 80 }
  PasswordField { id: pw; host: root; anchors.centerIn: parent }
}
```

`DesignBase` provides `time`, `hours`, `minutes`, `dateText`, `now`, `greeting`, `userName`, `lang`, `tr()`, the colours
`bg fg accent muted`, `font`, `withAlpha()`, `opt(key, def)` and a `preview` flag. Test it with
`omarchy-shell lock previewDesign my:Mine.qml`.

## SDDM themes (qylock)

Any SDDM theme written in QML can be the lock screen: the design id `sddm:<theme>` loads `designs/SddmHost.qml`, which
gives the theme what SDDM would — `sddm` (login, power actions, `loginFailed` / `loginSucceeded`), `config` (from
`theme.conf`, with `stringValue` / `boolValue` / `intValue`), `userModel`, `sessionModel`, `keyboard`. `sddm.login()`
only hands the password to the stock PAM flow of this plugin; a wrong password makes the theme play its own
`loginFailed`. If a theme fails to load, the stock view is shown; **Ctrl+Alt+Enter** on the lock screen drops a theme
whose input is broken and shows the stock password field.

The themes of [qylock](https://github.com/Darkkal44/qylock) (GPL-3.0; game art and video backgrounds) are not part of
this repo: `omarchy-lock-themes` (in the dotfiles, `scripts/bin`) downloads them to `~/.local/share/omarchy-lock-themes`
with a sparse clone and points their Qt5 imports at qylock's own shims. `list [--remote]`, `fetch <theme>… | --all`,
`set <theme>`, `preview <theme>`, `update`; `sddm <theme>` puts the same theme on the SDDM login screen (sudo, the original files — SDDM has its own `SddmComponents` and cannot read your home), `sddm-test <theme>` shows it in the real greeter in a window, `sddm reset` brings the Omarchy login back. In the Customizer: **Lock** → SDDM themes (download one or all, previews,
pick).

## Files

| File | |
|---|---|
| `LockHost.qml` | loads a design, falls back to the stock view |
| `designs/designs.json` | registry: `id`, `file`, `name`, `description`, `tags` |
| `designs/*.qml` | the designs and shared parts: `DesignBase`, `PasswordField`, `Wallpaper`, `Avatar` |

Rebasing onto a new Omarchy: `diff -u $OMARCHY_PATH/shell/plugins/lock/Service.qml Service.qml` and carry
the `// design:` blocks over.

In [my dotfiles](https://github.com/KamradSmeshnyavy/dotfiles) the design and every setting are picked in
the Customizer overlay, with previews rendered in the current theme.

## With the Customizer

[omarchy-customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) is one overlay (Super+Shift+T) with live preview for this plugin's settings and
the rest of the look & feel: themes, wallpapers, Hyprland animations, transparency, blur, screen shaders.
Install it next to this plugin (it finds the other companions on its own):

```sh
omarchy plugin add https://github.com/KamradSmeshnyavy/omarchy-customizer --enable
```

## Style designs

`style-flat`, `style-glass`, `style-fluent`, `style-paper`, `style-neumorph`, `style-brutal`, `style-retro`, `style-neon` —
the DOT-MATRIX layout (big clock, date, password field with dots, fingerprint hint, motto) in the finish of a Customizer
style: one `designs/StyleLock.qml` with `look`, tiny wrappers `designs/Style<Look>.qml`. Colours come from the theme.

## License

GPL-3.0 (see [LICENSE](LICENSE); earlier versions were MIT), credits — in [NOTICE](NOTICE). Based on `omarchy.lock`
from [Omarchy](https://github.com/basecamp/omarchy) (MIT, © David Heinemeier Hansson); the `glyph` design comes from
[glyph-rice](https://github.com/Nebelung-cloud/glyph-rice) (GPL-3.0). Inspired by
[omarchy-lock-explorer](https://github.com/SirJul1337/omarchy-lock-explorer); no code from it is used.

- **yami** — after yami's login screen ([Trendorin/yami](https://github.com/Trendorin/yami), MIT, own code): a big pixel Tiny5 clock with a hard shadow, the date, a lock · user line, a password box with a one-pixel border and a block cursor, sleep / reboot / power off, the host and keyboard layout in cells.
- **Cozytile** — after the SDDM themes of [Cozytile](https://github.com/Darkkal44/Cozytile) (no licence, look only, own code): the wallpaper under a 75 % black veil with falling, spinning petals; on the left a big Orbitron clock, the date in spaced capitals in the accent, the user name, a translucent password box with an accent outline and a CONFIRM button.
- **surface** — after the stellarium hyprlock of [surface-dots](https://github.com/snes19xx/surface-dots) (snes19xx, its README allows reuse with credit; own code): the wallpaper dimmed, a huge EB Garamond clock with the minutes in green italics and two dots for the colon, the date in italics, «Welcome back, name.», a dark password box with ENTER PASSPHRASE TO UNLOCK, the battery top right and the moon phase with its lit percentage bottom left (computed locally — no weather, the lock screen stays offline).
- **Rumda** — after Rumda's lock screen ([hexonide/rumda](https://github.com/hexonide/rumda), look only, own code): the wallpaper dimmed, a big bold clock in the warm accent, the date in a monospaced font, a small rounded password box with an italic «...password...».
