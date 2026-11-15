import QtQuick

// Rumda (по мотивам экрана блокировки Rumda, hexonide/rumda — только облик, код свой): обои темы, притемнённые до 70 %,
// выше центра — крупное жирное время цветом светлого акцента, под ним дата моноширинным шрифтом; внизу — маленькое
// скруглённое поле пароля с коричневой рамкой и курсивной подсказкой «...password...».
DesignBase {
  id: root
  field: pw

  readonly property color warm: Qt.lighter(root.accent, 1.12)
  readonly property string mono: Qt.fontFamilies().indexOf("Terminess Nerd Font") !== -1 ? "Terminess Nerd Font" : root.font

  Wallpaper { anchors.fill: parent; host: root; blur: 0 }
  Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.3) }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * 0.5 - 270 * Math.min(1, parent.height / 1080) - height / 2
    text: root.time
    color: root.warm
    font.family: root.font
    font.weight: Font.Bold
    font.pixelSize: Math.round(130 * Math.min(1, root.height / 1080))
  }
  Text {
    visible: root.showDate
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * 0.5 - 170 * Math.min(1, parent.height / 1080) - height / 2
    text: Qt.locale().toString(root.now, "dddd, MMMM dd")
    color: root.warm
    font.family: root.mono
    font.pixelSize: Math.round(32 * Math.min(1, root.height / 1080))
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * 0.5 + 450 * Math.min(1, parent.height / 1080) - height / 2
    width: Math.max(220, parent.width * 0.1); height: Math.max(38, parent.height * 0.04)
    radius: 8
    color: Qt.rgba(0.44, 0.28, 0.2, 0.1)
    border.width: 2
    border.color: root.failureMessage.length > 0 ? Qt.darker(root.accent, 1.3) : Qt.rgba(0.44, 0.28, 0.2, 1)
    PasswordField {
      id: pw
      host: root
      anchors.fill: parent
      bare: true
      fieldWidth: parent.width
      fieldHeight: parent.height
      fieldFontSize: 15
      dotFontSize: 14
      fontFamily: root.mono
      textColor: root.warm
      placeholderColor: root.warm
      placeholderText: root.authenticatingPassword ? "…" : "...password..."
    }
  }
}
