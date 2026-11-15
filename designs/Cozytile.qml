import QtQuick

// Cozytile (по мотивам SDDM-тем Cozytile, Darkkal44 — лицензии нет, только облик, код свой): обои под чёрной вуалью 75 %,
// сверху вниз падают и кружатся лепестки; слева по центру колонка 360 px — крупное время Orbitron, дата капителью с
// разрядкой цветом акцента, имя пользователя, поле пароля (полупрозрачное, рамка акцентом в фокусе, точки с широкой
// разрядкой) и кнопка «CONFIRM» с рамкой акцентом.
DesignBase {
  id: root
  field: pw

  readonly property real s: Math.min(1, height / 1080)
  readonly property string orb: Qt.fontFamilies().indexOf("Orbitron") !== -1 ? "Orbitron" : root.font
  property real ui: 0
  NumberAnimation on ui { from: 0; to: 1; duration: 1800; easing.type: Easing.OutCubic; running: true }

  Wallpaper { anchors.fill: parent; host: root; blur: 0 }
  Rectangle { anchors.fill: parent; color: "black"; opacity: 0.75 }

  // лепестки
  Repeater {
    model: root.reduceMotion ? 0 : 12
    Item {
      id: petal
      property real startX: Math.random() * root.width
      property real drift: (Math.random() - 0.5) * 160
      property real dur: 8000 + Math.random() * 8000
      property real sz: 6 + Math.random() * 8
      property real delay: Math.random() * 10000
      property real rot: Math.random() * 360
      x: startX; y: -20; width: sz; height: sz * 0.7; opacity: 0
      Rectangle { anchors.fill: parent; radius: width * 0.5; color: Qt.rgba(0.95, 0.8, 0.85, 0.7); rotation: petal.rot }
      SequentialAnimation {
        running: true; loops: Animation.Infinite
        PauseAnimation { duration: petal.delay }
        ParallelAnimation {
          NumberAnimation { target: petal; property: "y"; from: -20; to: root.height + 20; duration: petal.dur; easing.type: Easing.InOutQuad }
          NumberAnimation { target: petal; property: "x"; from: petal.startX; to: petal.startX + petal.drift; duration: petal.dur; easing.type: Easing.InOutQuad }
          NumberAnimation { target: petal; property: "rotation"; from: petal.rot; to: petal.rot + 720; duration: petal.dur }
          SequentialAnimation {
            NumberAnimation { target: petal; property: "opacity"; to: 0.85; duration: 1000 }
            PauseAnimation { duration: petal.dur - 2000 }
            NumberAnimation { target: petal; property: "opacity"; to: 0; duration: 1000 }
          }
        }
      }
    }
  }

  Column {
    anchors.left: parent.left
    anchors.leftMargin: 120 * root.s
    anchors.verticalCenter: parent.verticalCenter
    width: 360 * root.s
    spacing: 40 * root.s
    opacity: root.ui

    Column {
      spacing: 5 * root.s
      Text { text: Qt.formatTime(root.now, root.clock24 ? "HH:mm" : "hh:mm"); font.family: root.orb; font.pixelSize: 84 * root.s; font.weight: Font.DemiBold; color: "white" }
      Text {
        visible: root.showDate
        text: Qt.formatDate(root.now, "dddd, MMMM d").toUpperCase()
        font.family: root.orb; font.pixelSize: 13 * root.s; font.letterSpacing: 4 * root.s; font.weight: Font.Bold
        color: root.accent
      }
    }
    Column {
      width: parent.width
      spacing: 16 * root.s
      Text { text: (root.userName || "cozy user").toUpperCase(); font.family: root.orb; font.pixelSize: 18 * root.s; font.letterSpacing: 4 * root.s; font.weight: Font.DemiBold; color: "white" }
      Rectangle {
        width: parent.width; height: 50 * root.s
        radius: 4 * root.s
        color: Qt.rgba(0, 0, 0, 0.27)
        border.width: Math.max(1, root.s)
        border.color: root.failureMessage.length > 0 ? "#ff80a0" : pw.length > 0 || root.inputEnabled ? root.accent : Qt.rgba(1, 1, 1, 0.27)
        PasswordField {
          id: pw
          host: root
          anchors.fill: parent
          anchors.leftMargin: 16 * root.s
          anchors.rightMargin: 16 * root.s
          bare: true
          fieldWidth: parent.width - 32 * root.s
          fieldHeight: parent.height
          fieldFontSize: 13 * root.s
          dotFontSize: 14 * root.s
          dotLetterSpacing: 12 * root.s
          textAlignment: TextInput.AlignLeft
          fontFamily: root.orb
          textColor: "white"
          placeholderColor: Qt.rgba(1, 1, 1, 0.8)
          placeholderText: root.authenticatingPassword ? "…" : "Password..."
        }
      }
      Rectangle {
        width: parent.width; height: 50 * root.s
        radius: 4 * root.s
        color: ch.hovered ? root.accent : "transparent"
        border.width: Math.max(1, root.s)
        border.color: root.accent
        Text { anchors.centerIn: parent; text: "CONFIRM"; color: ch.hovered ? "black" : "white"; font.family: root.orb; font.pixelSize: 12 * root.s; font.letterSpacing: 4 * root.s; font.weight: Font.Bold }
        HoverHandler { id: ch; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: if (root.passwordText.length > 0 && !root.authenticatingPassword) root.submitPassword(root.passwordText) }
      }
      Text {
        visible: root.failureMessage.length > 0
        text: root.failureMessage
        color: "#ff80a0"; font.family: root.orb; font.pixelSize: 11 * root.s; font.weight: Font.Bold
      }
    }
  }
}
