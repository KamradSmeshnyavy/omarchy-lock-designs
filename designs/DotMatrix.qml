import QtQuick
import QtQuick.Shapes
import "../dotmatrix" as DotMatrix

// DOT-MATRIX: матричные обои без блюра, аппаратная рамка с внутренним контуром 1px,
// часы Doto Bold 128px, дата Space Mono, капсула пароля с круглыми LED-точками
// (красный появляется только при ошибке входа) и девиз ex nihilo внизу.
// Цвета и шрифты — dotmatrix/Palette.qml: тема omarchy или оригинальный монохром (dotmatrix.json).
DesignBase {
  id: root
  field: pw

  readonly property color cVoid: DotMatrix.Palette.bg
  readonly property color cOff: DotMatrix.Palette.unlit
  readonly property color cLine: DotMatrix.Palette.line
  readonly property color cMuted: DotMatrix.Palette.muted
  readonly property color cDim: DotMatrix.Palette.dim
  readonly property color cInk: DotMatrix.Palette.fg
  readonly property color cSignal: DotMatrix.Palette.danger

  readonly property string fontDot: DotMatrix.Palette.fontDot
  readonly property string fontMono: DotMatrix.Palette.fontMono

  readonly property int bezelWidth: 8
  readonly property int bezelRadius: 20

  readonly property real effectiveBlur: root.settings && root.settings.wallpaperBlur !== undefined
    ? Number(root.settings.wallpaperBlur)
    : 0
  readonly property real effectiveDim: root.settings && root.settings.wallpaperDim !== undefined
    ? Number(root.settings.wallpaperDim)
    : 0.45

  readonly property bool errorState: root.failureMessage.length > 0
  readonly property int dotCount: Math.min(pw.length, 28)
  readonly property real dotSize: dotCount > 18 ? 5 : (dotCount > 12 ? 6.5 : 8)
  readonly property real dotGap: dotCount > 18 ? 4 : (dotCount > 12 ? 6 : 8)

  function ntr(en, ru) {
    return root.lang === "ru" ? ru : en
  }

  readonly property string formattedDate: {
    var loc = Qt.locale(root.lang === "ru" ? "ru_RU" : "en_US")
    var day = loc.toString(root.now, "ddd").replace(/\./g, "")
    var num = Qt.formatDate(root.now, "dd")
    var mon = loc.toString(root.now, "MMM").replace(/\./g, "")
    return (day + " · " + num + " " + mon).toUpperCase()
  }

  Wallpaper {
    anchors.fill: parent
    host: root
    blur: root.effectiveBlur
    dim: root.effectiveDim
  }

  // Чёрная аппаратная рамка 8px со скруглёнными внутренними углами 20px и контуром 1px #2a2a2a.
  Shape {
    id: bezelShape
    anchors.fill: parent
    z: 10
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.cVoid
      fillRule: ShapePath.OddEvenFill
      strokeWidth: -1

      PathRectangle {
        x: 0
        y: 0
        width: bezelShape.width
        height: bezelShape.height
      }
      PathRectangle {
        x: root.bezelWidth
        y: root.bezelWidth
        width: Math.max(0, bezelShape.width - root.bezelWidth * 2)
        height: Math.max(0, bezelShape.height - root.bezelWidth * 2)
        radius: root.bezelRadius
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.cLine
      strokeWidth: 1

      PathRectangle {
        x: root.bezelWidth - 0.5
        y: root.bezelWidth - 0.5
        width: Math.max(0, bezelShape.width - root.bezelWidth * 2 + 1)
        height: Math.max(0, bezelShape.height - root.bezelWidth * 2 + 1)
        radius: root.bezelRadius + 0.5
      }
    }
  }

  // Матричные часы Doto Bold 128px (position: 0, +150 от центра).
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -150
    text: root.time
    color: root.cInk
    font.family: root.fontDot
    font.weight: Font.Bold
    font.pixelSize: 128
    renderType: Text.NativeRendering
  }

  // Дата в верхнем регистре Space Mono (position: 0, +50 от центра).
  Text {
    visible: root.showDate
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -50
    text: root.formattedDate
    color: root.cDim
    font.family: root.fontMono
    font.pixelSize: 13
    font.letterSpacing: 2.0
  }

  // Чёрная капсула ввода пароля 280×46 (position: 0, -40 от центра).
  Rectangle {
    id: pill
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 40
    width: 280
    height: 46
    radius: 23
    color: root.cVoid
    border.width: 1
    border.color: root.authenticatingPassword
      ? root.cMuted
      : (root.errorState ? root.cSignal : root.cLine)
    clip: true

    Behavior on border.color {
      ColorAnimation { duration: root.reduceMotion ? 0 : 160; easing.type: Easing.OutCubic }
    }

    // Невидимое поле ввода держит фокус, клавиатуру (Esc, Ctrl+U, Enter) и клики.
    PasswordField {
      id: pw
      host: root
      anchors.fill: parent
      fieldWidth: pill.width
      fieldHeight: pill.height
      bare: true
      opacity: 0
    }

    // Плейсхолдер / статус проверки / ошибка (когда поле пустое).
    Text {
      visible: pw.length === 0
      anchors.fill: parent
      anchors.leftMargin: 20
      anchors.rightMargin: 20
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      textFormat: Text.PlainText
      text: root.authenticatingPassword
        ? root.ntr("CHECKING…", "ПРОВЕРКА…")
        : (root.errorState
          ? (root.failureMessage || root.ntr("AUTH FAILED", "ОШИБКА ВХОДА")).toUpperCase()
          : root.ntr("PASSWORD", "ПАРОЛЬ"))
      color: root.authenticatingPassword
        ? root.cMuted
        : (root.errorState ? root.cSignal : root.cMuted)
      font.family: root.fontMono
      font.pixelSize: 11
      font.letterSpacing: 2.2
    }

    // Дискретные круглые LED-точки для введённых символов.
    Row {
      visible: pw.length > 0
      anchors.centerIn: parent
      spacing: root.dotGap

      Repeater {
        model: root.dotCount

        delegate: Rectangle {
          width: root.dotSize
          height: root.dotSize
          radius: root.dotSize / 2
          color: root.cInk
          scale: root.reduceMotion ? 1 : 0
          Component.onCompleted: scale = 1

          Behavior on scale {
            NumberAnimation {
              duration: root.reduceMotion ? 0 : 120
              easing.type: Easing.OutCubic
            }
          }
        }
      }
    }
  }

  // Подсказка сканера отпечатка пальца (position: 0, -110 от центра).
  Text {
    visible: root.fingerprintConfigured
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: 110
    text: "󰈷  " + root.ntr("TOUCH THE SENSOR", "КОСНИТЕСЬ СЕНСОРА")
    color: root.cMuted
    font.family: root.fontMono
    font.pixelSize: 10
    font.letterSpacing: 1.8
  }

  // Девиз внизу экрана (40px от нижнего края).
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    text: String(root.opt("motto", "ex nihilo"))
    color: root.cMuted
    opacity: 0.55
    font.family: root.fontMono
    font.pixelSize: 10
    font.letterSpacing: 5.5
  }
}
