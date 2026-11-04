import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons as Commons

// Лок по стилю Customizer: структура дизайна Nihil (обои, крупные часы, дата, поле пароля с точками,
// подсказка отпечатка, девиз внизу) в отделке стиля — `look` задают обёртки StyleFlat.qml, StylePaper.qml, …
//   flat     тонкие часы, квадратное поле, полоска акцента под ним
//   glass    поле-капсула из матового стекла, мягкая тень
//   fluent   скруглённая карточка поля с акцентной полоской снизу, тень
//   paper    рукописные часы, поле — полоска бумаги со скотчем и карандашной строкой, «чернильные» точки
//   neumorph вдавленное поле на «пластике», двойные тени, круглые точки
//   brutal   жирные часы, поле с толстой рамкой и жёсткой тенью, квадратные точки
//   retro    окно «вход в систему» с заголовком и кантом, пиксельный шрифт, звёздочки вместо точек
//   neon     моно-часы со свечением акцента, поле с неоновой рамкой
// Цвета — из темы (DesignBase: bg, fg, accent, muted), обои — как у остальных дизайнов.
DesignBase {
  id: root
  field: pw

  property string look: "flat"
  function pick(map) { return map[root.look] !== undefined ? map[root.look] : map["flat"] }
  function ntr(en, ru) { return root.lang === "ru" ? ru : en }

  readonly property var families: Qt.fontFamilies()
  function face(name, fallback) { return families.indexOf(name) >= 0 ? name : fallback }
  readonly property string hand: root.face("Caveat", root.font)
  readonly property string pixel: root.face("Pixelify Sans", root.font)
  readonly property string clockFont: root.pick({ paper: root.hand, retro: root.pixel, neon: Commons.Style.font.family, flat: root.font })
  readonly property string textFont: root.pick({ paper: root.face("Pangolin", root.hand), retro: root.pixel, neon: Commons.Style.font.family, flat: root.font })
  readonly property int clockSize: root.pick({ paper: 150, retro: 96, brutal: 132, neon: 112, flat: 120 })
  readonly property int clockWeight: root.pick({ brutal: Font.Black, retro: Font.Normal, paper: Font.Normal, flat: Font.Light })
  readonly property bool upper: root.pick({ brutal: true, neon: true, flat: false })
  function cap(s) { return root.upper ? String(s).toUpperCase() : String(s) }

  readonly property bool errorState: root.failureMessage.length > 0
  readonly property color danger: Commons.Color.urgent
  readonly property color surface: Qt.tint(root.bg, Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06))
  readonly property bool dark: 0.299 * root.bg.r + 0.587 * root.bg.g + 0.114 * root.bg.b < 0.45
  function lift(c, k) { return Qt.rgba(c.r + (1 - c.r) * k, c.g + (1 - c.g) * k, c.b + (1 - c.b) * k, 1) }
  function shade(c, k) { return Qt.rgba(c.r * k, c.g * k, c.b * k, 1) }
  readonly property string grain: Quickshell.env("HOME") + "/.config/omarchy/plugins/kamradsmeshnyavy.customizer/textures/"
    + (root.dark ? "paper-dark.png" : "paper.png")

  readonly property real effectiveBlur: root.settings && root.settings.wallpaperBlur !== undefined ? Number(root.settings.wallpaperBlur) : 0.4
  readonly property real effectiveDim: root.settings && root.settings.wallpaperDim !== undefined ? Number(root.settings.wallpaperDim) : 0.35

  readonly property string formattedDate: {
    var loc = Qt.locale(root.lang === "ru" ? "ru_RU" : "en_US")
    return loc.toString(root.now, "dddd, d MMMM")
  }

  Wallpaper {
    anchors.fill: parent
    host: root
    blur: root.effectiveBlur
    dim: root.effectiveDim
  }

  // ── часы и дата ─────────────────────────────────────────────────────
  Text {
    id: clock
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -150
    text: root.time
    color: root.look === "neon" ? root.accent : root.fg
    font.family: root.clockFont
    font.pixelSize: root.clockSize
    font.weight: root.clockWeight
    rotation: root.look === "paper" ? -2 : 0
    layer.enabled: root.look === "neon" || root.look === "brutal"
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: root.look === "neon" ? root.accent : root.fg
      shadowOpacity: root.look === "neon" ? 0.9 : 1
      shadowBlur: root.look === "neon" ? 1.0 : 0
      shadowHorizontalOffset: root.look === "brutal" ? 5 : 0
      shadowVerticalOffset: root.look === "brutal" ? 5 : 0
    }
  }
  Text {
    visible: root.showDate
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: clock.bottom
    anchors.topMargin: root.look === "paper" ? 0 : 6
    text: root.cap(root.formattedDate)
    color: root.look === "neon" ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.8)
    font.family: root.textFont
    font.pixelSize: root.look === "paper" ? 26 : 16
    font.letterSpacing: root.upper ? 2.5 : 0.5
  }

  // ── поле пароля ─────────────────────────────────────────────────────
  Item {
    id: box
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: root.look === "retro" ? 70 : 50
    width: root.look === "retro" ? 360 : 300
    height: root.look === "retro" ? 120 : 50

    // brutal: жёсткая тень; neumorph: светлая тень вверх-влево.
    Rectangle {
      visible: root.look === "brutal"
      x: 6; y: 6; width: parent.width; height: parent.height
      color: root.fg
    }
    Rectangle {
      id: plate
      anchors.fill: parent
      radius: root.pick({ glass: 25, neumorph: 25, fluent: 10, neon: 10, paper: 2, flat: 0 })
      rotation: root.look === "paper" ? -1 : 0
      color: root.pick({
        glass: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.55), neon: Qt.rgba(root.bg.r * 0.6, root.bg.g * 0.6, root.bg.b * 0.6, 0.9),
        neumorph: root.shade(root.bg, root.dark ? 0.82 : 0.94), paper: root.lift(root.bg, root.dark ? 0.06 : 0.5),
        retro: root.lift(root.bg, root.dark ? 0.14 : 0.3), flat: root.surface
      })
      border.width: root.pick({ brutal: 3, neon: 1.5, glass: 1, fluent: 1, paper: 1, neumorph: 0, retro: 0, flat: 0 })
      border.color: root.errorState ? root.danger : root.pick({
        brutal: root.fg, neon: root.accent, glass: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.25),
        fluent: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12), paper: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.3), flat: "transparent"
      })
      layer.enabled: root.look === "glass" || root.look === "fluent" || root.look === "neon" || root.look === "neumorph" || root.look === "paper"
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.look === "neon" ? root.accent : (root.look === "neumorph" ? root.lift(root.bg, root.dark ? 0.12 : 0.85) : "#000000")
        shadowOpacity: root.pick({ neon: 0.9, neumorph: 0.9, paper: 0.35, flat: 0.35 })
        shadowBlur: root.pick({ neon: 1.0, neumorph: 0.7, flat: 0.7 })
        shadowHorizontalOffset: root.look === "neumorph" ? -5 : 0
        shadowVerticalOffset: root.look === "neumorph" ? -5 : (root.look === "neon" ? 0 : 3)
      }
      // paper: зерно бумаги.
      Image {
        visible: root.look === "paper"
        anchors.fill: parent
        source: visible ? "file://" + root.grain : ""
        fillMode: Image.Tile
        opacity: 0.8
        asynchronous: true
      }
    }
    // paper: скотч и карандашная строка.
    Rectangle {
      visible: root.look === "paper"
      width: 70; height: 20; x: parent.width / 2 - 35; y: -10; rotation: 3
      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
    }
    Rectangle {
      visible: root.look === "paper"
      x: 24; width: parent.width - 48; height: 1.5; y: parent.height - 12
      color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.45)
    }
    // flat / fluent: полоска акцента снизу.
    Rectangle {
      visible: root.look === "flat" || root.look === "fluent"
      anchors.bottom: plate.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.look === "flat" ? parent.width : 48
      height: 3
      radius: root.look === "fluent" ? 1.5 : 0
      color: root.errorState ? root.danger : root.accent
    }
    // retro: окно «вход в систему» — кант, заголовок, вдавленное поле.
    Item {
      visible: root.look === "retro"
      anchors.fill: parent
      Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 2; color: root.lift(plate.color, 0.5) }
      Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 2; color: root.lift(plate.color, 0.5) }
      Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; color: root.shade(plate.color, 0.4) }
      Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 2; color: root.shade(plate.color, 0.4) }
      Rectangle {
        x: 4; y: 4; width: parent.width - 8; height: 24
        color: root.accent
        Text {
          anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
          text: root.ntr("Log On — ", "Вход — ") + root.userName
          color: (0.299 * root.accent.r + 0.587 * root.accent.g + 0.114 * root.accent.b) > 0.55 ? "#111111" : "#ffffff"
          font.family: root.pixel; font.pixelSize: 14; font.bold: true
        }
      }
      Text {
        x: 16; y: 44
        text: root.ntr("Password:", "Пароль:")
        color: root.fg
        font.family: root.pixel; font.pixelSize: 14
      }
      Rectangle {
        id: well
        x: 16; y: 66; width: parent.width - 32; height: 36
        color: root.lift(plate.color, 0.75)
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 2; color: root.shade(plate.color, 0.45) }
        Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 2; color: root.shade(plate.color, 0.45) }
      }
    }

    // Невидимое поле ввода держит фокус и клавиатуру (как у Nihil).
    PasswordField {
      id: pw
      host: root
      anchors.fill: parent
      fieldWidth: box.width
      fieldHeight: box.height
      bare: true
      opacity: 0
    }

    // Подсказка / проверка / ошибка, пока поле пустое.
    Text {
      visible: pw.length === 0
      x: root.look === "retro" ? 26 : 20
      y: root.look === "retro" ? 66 : 0
      width: root.look === "retro" ? parent.width - 52 : parent.width - 40
      height: root.look === "retro" ? 36 : parent.height
      horizontalAlignment: root.look === "retro" ? Text.AlignLeft : Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      text: root.authenticatingPassword ? root.ntr("Checking…", "Проверка…")
        : (root.errorState ? (root.failureMessage || root.ntr("Wrong password", "Неверный пароль"))
          : (root.look === "retro" ? "" : root.cap(root.ntr("Password", "Пароль"))))
      color: root.errorState ? root.danger : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55)
      font.family: root.textFont
      font.pixelSize: root.look === "paper" ? 22 : 14
      font.letterSpacing: root.upper ? 2 : 0.3
    }

    // Введённые символы: точки по стилю, у ретро — звёздочки.
    Row {
      visible: pw.length > 0
      x: root.look === "retro" ? 26 : (parent.width - width) / 2
      y: root.look === "retro" ? 66 + (36 - height) / 2 : (parent.height - height) / 2
      spacing: root.look === "retro" ? 2 : 8
      Repeater {
        model: Math.min(pw.length, 24)
        delegate: Item {
          required property int index
          width: root.look === "retro" ? 10 : 9
          height: root.look === "retro" ? 18 : 9
          Rectangle {
            visible: root.look !== "retro"
            anchors.fill: parent
            radius: root.look === "brutal" || root.look === "flat" ? 0 : width / 2
            rotation: root.look === "paper" ? (index * 37) % 20 - 10 : 0
            scale: root.look === "paper" ? 0.85 + ((index * 13) % 5) * 0.08 : 1
            color: root.look === "neon" ? root.accent : root.fg
          }
          Text {
            visible: root.look === "retro"
            anchors.centerIn: parent
            text: "*"
            color: root.fg
            font.family: root.pixel; font.pixelSize: 18
          }
        }
      }
    }
  }

  Text {
    visible: root.fingerprintConfigured
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: box.bottom
    anchors.topMargin: 26
    text: "󰈷  " + root.cap(root.ntr("Touch the sensor", "Коснитесь сенсора"))
    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
    font.family: root.textFont
    font.pixelSize: root.look === "paper" ? 20 : 12
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    text: root.cap(String(root.opt("motto", root.greeting)))
    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55)
    font.family: root.textFont
    font.pixelSize: root.look === "paper" ? 24 : 13
    font.letterSpacing: root.upper ? 3 : 0.5
  }
}
