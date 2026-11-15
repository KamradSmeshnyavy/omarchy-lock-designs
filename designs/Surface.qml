import QtQuick
import Quickshell
import Quickshell.Services.UPower

// surface (по мотивам hyprlock «stellarium» из surface-dots, snes19xx; README разрешает брать со ссылкой; код свой):
// обои притемнены, выше центра — огромное время EB Garamond: часы цветом бумаги, двоеточие — две приглушённые точки,
// минуты — курсивом зеленью; под ним курсивом дата «Thursday, 2 July 2026». Справа сверху — заряд зеленью. Внизу —
// «Welcome back, имя.» (имя курсивом зеленью), тёмное скруглённое поле пароля и «ENTER PASSPHRASE TO UNLOCK»
// разрядкой; слева внизу — фаза Луны (считается локально) и её освещённость. Погоду, как у него, не берём —
// экран блокировки не ходит в сеть.
DesignBase {
  id: root
  field: pw

  readonly property color paper: "#d3c6aa"
  readonly property color green: Qt.rgba(0.655, 0.753, 0.502, 1)
  readonly property string serif: Qt.fontFamilies().indexOf("EB Garamond") !== -1 ? "EB Garamond" : "serif"
  readonly property string mono: Qt.fontFamilies().indexOf("CMU Typewriter Text") !== -1 ? "CMU Typewriter Text" : "monospace"
  readonly property real k: Math.min(1, height / 1000)

  // фаза Луны: возраст от новолуния 6 января 2000, 18:14 UTC, синодический месяц 29,53059 сут
  readonly property real moonAge: {
    var d = (now.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000
    var a = d % 29.53059
    return a < 0 ? a + 29.53059 : a
  }
  readonly property real moonLit: (1 - Math.cos(2 * Math.PI * moonAge / 29.53059)) / 2
  readonly property string moonName: {
    var a = moonAge
    if (a < 1.84566) return "New Moon"
    if (a < 5.53699) return "Waxing Crescent"
    if (a < 9.22831) return "First Quarter"
    if (a < 12.91963) return "Waxing Gibbous"
    if (a < 16.61096) return "Full Moon"
    if (a < 20.30228) return "Waning Gibbous"
    if (a < 23.99361) return "Last Quarter"
    if (a < 27.68493) return "Waning Crescent"
    return "New Moon"
  }

  Wallpaper { anchors.fill: parent; host: root; blur: 0 }
  Rectangle { anchors.fill: parent; color: Qt.rgba(7 / 255, 9 / 255, 11 / 255, 0.55) }

  // заряд
  Row {
    readonly property var dev: UPower.displayDevice
    visible: !!dev && dev.isLaptopBattery !== false && dev.ready
    anchors { right: parent.right; top: parent.top; rightMargin: 36 * root.k; topMargin: 34 * root.k }
    spacing: 8
    Text {
      text: parent.dev ? Math.round(parent.dev.percentage * (parent.dev.percentage <= 1 ? 100 : 1)) + "%" : ""
      font.family: root.mono; font.pixelSize: Math.round(15 * root.k); color: root.green
    }
    Text { text: "\u{F0079}"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Math.round(15 * root.k); color: root.green }
  }

  // время
  Row {
    id: clock
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * 0.5 - 300 * root.k
    spacing: 16 * root.k
    Text { text: root.hours; font.family: root.serif; font.pixelSize: Math.round(170 * root.k); color: Qt.rgba(0.94, 0.925, 0.9, 1) }
    Column {
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: 14 * root.k
      spacing: 30 * root.k
      Repeater { model: 2; Rectangle { width: 22 * root.k; height: width; radius: width / 2; color: Qt.rgba(0.6, 0.57, 0.5, 1) } }
    }
    Text { text: root.minutes; font.family: root.serif; font.italic: true; font.pixelSize: Math.round(170 * root.k); color: root.green }
  }
  Text {
    visible: root.showDate
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: clock.bottom
    anchors.topMargin: -18 * root.k
    text: Qt.formatDate(root.now, "dddd, d MMMM yyyy")
    font.family: root.serif; font.italic: true; font.pixelSize: Math.round(30 * root.k)
    color: root.paper
  }

  // приветствие и поле
  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height - 150 * root.k
    spacing: 14 * root.k
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.StyledText
      text: "Welcome back, <i><font color='" + root.green + "'>" + root.userName + "</font></i>."
      font.family: root.serif; font.pixelSize: Math.round(22 * root.k); color: Qt.rgba(0.94, 0.925, 0.9, 1)
    }
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 200 * root.k; height: 36 * root.k
      radius: 7
      color: Qt.rgba(0.11, 0.13, 0.14, 0.72)
      border.width: 1
      border.color: root.failureMessage.length > 0 ? "#e67e80" : Qt.rgba(0.655, 0.753, 0.502, 0.35)
      PasswordField {
        id: pw
        host: root
        anchors.fill: parent
        bare: true
        fieldWidth: parent.width
        fieldHeight: parent.height
        fieldFontSize: 13
        dotFontSize: 12
        fontFamily: root.mono
        textColor: Qt.rgba(0.94, 0.925, 0.9, 1)
        placeholderColor: Qt.rgba(0.83, 0.78, 0.67, 0.5)
        placeholderText: root.authenticatingPassword ? "…" : ""
      }
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.failureMessage.length > 0 ? root.failureMessage.toUpperCase() : "ENTER PASSPHRASE TO UNLOCK"
      font.family: root.mono; font.pixelSize: Math.round(10 * root.k); font.letterSpacing: 3 * root.k
      color: Qt.rgba(0.6, 0.6, 0.55, 0.8)
    }
  }

  // Луна
  Row {
    anchors { left: parent.left; bottom: parent.bottom; leftMargin: 40 * root.k; bottomMargin: 34 * root.k }
    spacing: 14 * root.k
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 22 * root.k; height: 1; color: Qt.rgba(0.83, 0.78, 0.67, 0.6) }
    Canvas {
      id: moon
      anchors.verticalCenter: parent.verticalCenter
      width: 24 * root.k; height: width
      readonly property real age: root.moonAge
      onAgeChanged: requestPaint()
      onPaint: {
        var c = getContext("2d"), r = width / 2 - 1
        c.reset()
        c.translate(width / 2, height / 2)
        c.fillStyle = "#2b2f33"
        c.beginPath(); c.arc(0, 0, r, 0, 2 * Math.PI); c.fill()
        // освещённая половина диска (растущая — справа, убывающая — слева), затем эллипс терминатора
        var f = root.moonAge / 29.53059, waxing = f < 0.5
        var x = Math.cos(2 * Math.PI * f) * r
        c.fillStyle = "#f3d9a0"
        c.save()
        c.beginPath()
        if (waxing) c.rect(0, -r, r, 2 * r); else c.rect(-r, -r, r, 2 * r)
        c.clip()
        c.beginPath(); c.arc(0, 0, r, 0, 2 * Math.PI); c.fill()
        c.restore()
        // терминатор: эллипс тени (до половины) или света (после половины)
        c.fillStyle = x > 0 ? "#2b2f33" : "#f3d9a0"
        c.beginPath(); c.ellipse(-Math.abs(x), -r, 2 * Math.abs(x), 2 * r); c.fill()
      }
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.StyledText
      text: "<i>" + root.moonName + "</i> <font color='#8f8a7c'>· " + Math.round(root.moonLit * 100) + "% lit</font>"
      font.family: root.mono; font.pixelSize: Math.round(19 * root.k); color: Qt.rgba(0.94, 0.925, 0.9, 0.9)
    }
  }
}
