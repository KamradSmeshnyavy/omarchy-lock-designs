import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons as Commons

// Liquid — экран блокировки по мотивам Vitreus (github.com/natepayn3/Vitreus, MIT; код свой, формы символов —
// lockscreen/shapes.svg оттуда): обои резкие и расплываются, потом поднимаются по очереди часы со свечением, дата,
// аватар в стеклянном круге и стеклянная пилюля пароля. Каждый символ — случайная фигура из 16 (повёрнута на четверть
// оборота), сам пароль не рисуется. Неверный пароль — пилюля вспыхивает красным и трясётся. Пароль — стоковый PAM.
// Настройки lock-design.json: liquidBlur (0…1, по умолчанию 0.7), wallpaperDim, clock24, liquidShapes (shapes | dots).
DesignBase {
  id: root
  field: pw

  readonly property var maskPaths: ["M 12,2 A 10,10 0 1 0 12,22 A 10,10 0 1 0 12,2 Z", "M 12,2 L 22,12 L 12,22 L 2,12 Z", "M 5,3 L 19,3 C 20.1,3 21,3.9 21,5 L 21,19 C 21,20.1 20.1,21 19,21 L 5,21 C 3.9,21 3,20.1 3,19 L 3,5 C 3,3.9 3.9,3 5,3 Z", "M 12,2.5 L 22.5,20.5 L 1.5,20.5 Z", "M 1.5,3.5 L 22.5,3.5 L 12,21.5 Z", "M 12,2 L 21.5,7.5 L 21.5,16.5 L 12,22 L 2.5,16.5 L 2.5,7.5 Z", "M 12,2 L 22,9.2 L 18.2,21 L 5.8,21 L 2,9.2 Z", "M 7.5,2 L 16.5,2 L 22,7.5 L 22,16.5 L 16.5,22 L 7.5,22 L 2,16.5 L 2,7.5 Z", "M 12,2 Q 12,12 2,12 Q 12,12 12,22 Q 12,12 22,12 Q 12,12 12,2 Z", "M 12,2 L 15,8.5 L 22,9.3 L 17,14 L 18.5,21 L 12,17.5 L 5.5,21 L 7,14 L 2,9.3 L 9,8.5 Z", "M 9,3 L 15,3 L 15,9 L 21,9 L 21,15 L 15,15 L 15,21 L 9,21 L 9,15 L 3,15 L 3,9 L 9,9 Z", "M 12,21.35 L 10.55,20.03 C 5.4,15.36 2,12.28 2,8.5 C 2,5.42 4.42,3 7.5,3 C 9.24,3 10.91,3.81 12,5.09 C 13.09,3.81 14.76,3 16.5,3 C 19.58,3 22,5.42 22,8.5 C 22,12.28 18.6,15.36 13.45,20.03 Z", "M 12,2 A 10,10 0 0 0 22,14 A 10,10 0 1 1 12,2 Z", "M 12,2 L 20.5,5.5 L 20.5,11.5 C 20.5,16.8 16.9,21.2 12,22 C 7.1,21.2 3.5,16.8 3.5,11.5 L 3.5,5.5 Z", "M 11,2 L 13,2 L 13,7.5 L 17.5,4.8 L 18.5,6.5 L 14,9.5 L 19,12 L 19,14 L 14,14.5 L 18.5,17.5 L 17.5,19.2 L 13,16.5 L 13,22 L 11,22 L 11,16.5 L 6.5,19.2 L 5.5,17.5 L 10,14.5 L 5,14 L 5,12 L 10,9.5 L 5.5,6.5 L 6.5,4.8 L 11,7.5 Z", "M 12,2 A 10,10 0 1 0 12,22 A 10,10 0 1 0 12,2 Z M 12,6 A 6,6 0 1 1 12,18 A 6,6 0 1 1 12,6 Z"]
  readonly property bool fail: root.failureMessage.length > 0
  readonly property bool busy: root.authenticatingPassword
  readonly property bool dots: String(root.opt("liquidShapes", "shapes")) === "dots"
  readonly property real blurTo: Number(root.opt("liquidBlur", 0.7))
  function ntr(en, ru) { return root.lang === "ru" ? ru : en }

  // появление: обои резкие → размытие, затем часы, дата, аватар, поле — по очереди
  property real t: root.reduceMotion ? 1 : 0
  Component.onCompleted: { t = 1; syncMarks() }
  Behavior on t { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
  function ph(a, b) { var x = Math.max(0, Math.min(1, (t - a) / (b - a))); return 1 - Math.pow(1 - x, 3) }

  // фигуры введённых символов: на каждый символ — своя случайная (номер, поворот, оттенок), живут, пока символ есть
  property var marks: []
  // в превью ввода нет — шесть фигур-образцов, чтобы было видно, как выглядит пароль
  property int typed: root.preview ? 6 : pw.length
  function syncMarks() {
    var m = marks.slice(0, typed)
    while (m.length < typed) m.push({ s: Math.floor(Math.random() * 16), r: Math.floor(Math.random() * 4) * 90, h: Math.random() })
    marks = m
  }
  onTypedChanged: syncMarks()

  readonly property color glass: Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color bad: Commons.Color.urgent

  Wallpaper {
    anchors.fill: parent
    host: root
    blur: root.blurTo * root.ph(0, 0.45)
    dim: Number(root.opt("wallpaperDim", 0.25))
  }

  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -40
    spacing: 22

    // часы со свечением
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: clock.implicitWidth
      height: clock.implicitHeight
      opacity: root.ph(0.3, 0.6)
      transform: Translate { y: 30 * (1 - root.ph(0.3, 0.6)) }
      Text {
        id: clock
        text: Qt.formatTime(root.now, root.clock24 ? "HH:mm" : "h:mm")
        color: "#f4f6f8"
        font { family: root.font; pixelSize: 168; weight: Font.Black; letterSpacing: -6 }
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(1, 1, 1, 0.55); shadowBlur: 0.9; blurMax: 48; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
      }
      Rectangle {
        visible: !root.clock24
        anchors { left: clock.right; leftMargin: 10; verticalCenter: clock.verticalCenter; verticalCenterOffset: -20 }
        width: ap.implicitWidth + 18; height: 26; radius: 13
        color: Qt.rgba(1, 1, 1, 0.16)
        Text { id: ap; anchors.centerIn: parent; text: Qt.formatTime(root.now, "AP"); color: "#f4f6f8"; font { family: root.font; pixelSize: 12; weight: Font.DemiBold } }
      }
    }
    Text {
      visible: root.showDate
      anchors.horizontalCenter: parent.horizontalCenter
      opacity: root.ph(0.4, 0.7)
      text: Qt.locale(root.lang === "ru" ? "ru_RU" : "en_US").toString(root.now, "dddd, d MMMM yyyy")
      color: Qt.rgba(1, 1, 1, 0.85)
      font { family: root.font; pixelSize: 22; weight: Font.Medium }
    }

    // аватар в стеклянном круге
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 132; height: 132
      opacity: root.ph(0.5, 0.8)
      transform: Translate { y: 24 * (1 - root.ph(0.5, 0.8)) }
      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
        border { width: 2; color: Qt.rgba(1, 1, 1, 0.55) }
      }
      Avatar { anchors.fill: parent; anchors.margins: 4; host: root }
    }
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 4
      opacity: root.ph(0.55, 0.85)
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.userName; color: "#f4f6f8"; font { family: root.font; pixelSize: 22; weight: Font.DemiBold } }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.busy ? root.ntr("Checking…", "Проверка…") : root.fail ? root.ntr("Wrong password", "Неверный пароль") : root.ntr("System locked", "Система заблокирована")
        color: root.fail ? root.bad : Qt.rgba(1, 1, 1, 0.7)
        font { family: root.font; pixelSize: 13 }
      }
    }

    // стеклянная пилюля пароля: замок слева, фигуры, стрелка справа
    Item {
      id: pillBox
      anchors.horizontalCenter: parent.horizontalCenter
      width: 360; height: 56
      opacity: root.ph(0.65, 1)
      transform: Translate { id: shake; y: 20 * (1 - root.ph(0.65, 1)) }
      Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: root.fail ? Qt.rgba(root.bad.r, root.bad.g, root.bad.b, 0.35) : Qt.rgba(1, 1, 1, 0.16)
        border { width: 1.5; color: root.fail ? root.bad : Qt.rgba(1, 1, 1, 0.5) }
        Behavior on color { ColorAnimation { duration: 200 } }
        // блик по верхней кромке
        Rectangle {
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
          height: parent.height / 2 - 3
          radius: height / 2
          gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.22) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
          }
        }
      }
      Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: "󰌾"; color: Qt.rgba(1, 1, 1, 0.8); font.pixelSize: 18 }

      PasswordField {
        id: pw
        host: root
        anchors.fill: parent
        fieldWidth: pillBox.width
        fieldHeight: pillBox.height
        bare: true
        opacity: 0
      }

      Row {
        anchors { left: parent.left; leftMargin: 52; right: go.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 8
        clip: true
        layoutDirection: Qt.LeftToRight
        Repeater {
          model: root.marks.length
          Item {
            id: mk
            required property int index
            readonly property var m: root.marks[index] || { s: 0, r: 0, h: 0 }
            width: 18; height: 18
            Shape {
              anchors.centerIn: parent
              width: 24; height: 24
              rotation: mk.m.r
              scale: 18 / 24
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                strokeColor: "transparent"
                fillColor: root.fail ? root.bad : root.dots ? "#f4f6f8" : Qt.hsla((root.accent.hslHue + (mk.m.h - 0.5) * 0.25 + 1) % 1, Math.max(0.45, root.accent.hslSaturation), 0.72, 1)
                PathSvg { path: root.dots ? root.maskPaths[0] : root.maskPaths[mk.m.s] }
              }
            }
            NumberAnimation on scale { from: 0.2; to: 1; duration: 220; easing.type: Easing.OutBack }
          }
        }
      }
      Text {
        visible: root.marks.length === 0
        anchors { left: parent.left; leftMargin: 52; verticalCenter: parent.verticalCenter }
        text: root.fingerprintConfigured ? root.ntr("Password or fingerprint", "Пароль или отпечаток") : root.ntr("Password", "Пароль")
        color: Qt.rgba(1, 1, 1, 0.55)
        font { family: root.font; pixelSize: 15 }
      }
      Rectangle {
        id: go
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        width: 40; height: 40; radius: 20
        color: Qt.rgba(1, 1, 1, root.marks.length ? 0.9 : 0.3)
        Text { anchors.centerIn: parent; text: "󰁔"; color: "#1c2128"; font.pixelSize: 20 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.passwordText.length) root.submitPassword(root.passwordText) }
      }

      SequentialAnimation {
        id: shakeAnim
        loops: 2
        NumberAnimation { target: pillBox; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
        NumberAnimation { target: pillBox; property: "anchors.horizontalCenterOffset"; to: 12; duration: 80 }
        NumberAnimation { target: pillBox; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
      }
      Connections { target: root; function onFailedAttemptsChanged() { if (root.failedAttempts > 0 && !root.reduceMotion) shakeAnim.restart() } }
    }
  }
}
