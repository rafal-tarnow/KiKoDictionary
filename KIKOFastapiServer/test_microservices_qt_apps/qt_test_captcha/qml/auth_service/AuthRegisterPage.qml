import QtQuick
import QtQuick.Controls
import "../common"

ScrollablePage {
    id: page

    Column{
        spacing: 40
        anchors.right: parent.right
        anchors.left: parent.left

        Text{
            text:"AUTH REGISTER:"
        }

        TextField {
            id: userEmail
            anchors.right: parent.right
            anchors.left: parent.left
            placeholderText: qsTr("email")
        }

        TextField{
            id:userName
            anchors.right: parent.right
            anchors.left: parent.left
            placeholderText: qsTr("username")
        }

        TextField {
            id: userPassword
            anchors.right: parent.right
            anchors.left: parent.left
            placeholderText: qsTr("password")
        }

        Button{
            anchors.right: parent.right
            anchors.left: parent.left
            text: "Register"
            onClicked: {
                authManager.registerUser(userEmail.text, userName.text, userPassword.text)
            }
        }

    }
}
