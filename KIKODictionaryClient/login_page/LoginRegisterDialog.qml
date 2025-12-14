import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Dialog {
    id: inputDialog

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    parent: Overlay.overlay

    focus: true
    modal: true
    //title: qsTr("Input")
    standardButtons: Dialog.Cancel

    ColumnLayout {
        spacing: 20
        anchors.fill: parent
        Button{
            text: qsTr("Login")
            Layout.fillWidth: true
        }
        Label {
            elide: Label.ElideMiddle
            text: qsTr("or")
            Layout.fillWidth: true
        }
        Button{
            text: qsTr("Register")
            Layout.fillWidth: true
        }
    }
}
