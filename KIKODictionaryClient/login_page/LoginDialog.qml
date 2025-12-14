import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QtExampleStyle

Dialog {
    id: loginDialog

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    parent: Overlay.overlay
    popupType: Popup.Item

    focus: true
    modal: true
    title: qsTr("Login")

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            // ToolButton {
            //     text: qsTr("‹")
            //     //onClicked: stack.pop()
            // }
            Label {
                text: qsTr("Login")

                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
            ToolButton {
                text: qsTr("x")
                onClicked: loginDialog.close()
            }
        }
    }

    //standardButtons: Dialog.Ok | Dialog.Cancel

    ColumnLayout{
        LoginComponent{
            Layout.fillWidth: true

            Connections{
                target: authManager
                function onLoginSuccess(success){
                    loginDialog.close()
                }
            }
        }
        RowLayout{
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.preferredWidth: 200
            MenuSeparator{
                Layout.fillWidth: true
            }
            Text{
                text: qsTr("or")
            }
            MenuSeparator{
                Layout.fillWidth: true
            }
        }
        Button{
            id: registerButton
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.preferredWidth: 200
            text: qsTr("Register")
        }
    }
}
