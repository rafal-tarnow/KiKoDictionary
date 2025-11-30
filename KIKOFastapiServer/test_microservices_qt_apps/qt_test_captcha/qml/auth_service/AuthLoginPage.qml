import QtQuick
import QtQuick.Controls
import "../common"

ScrollablePage {
    id: page

    Column{
        spacing: 20
        anchors.right: parent.right
        anchors.left: parent.left

        Text{
            text:"AUTH LOGIN:"
        }

        TextField {
            id: userEmail
            anchors.right: parent.right
            anchors.left: parent.left
            placeholderText: qsTr("email")
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
            text: "Login"
            onClicked: {
                authManager.loginUser(userEmail.text, userPassword.text)
            }
        }

        Button{
            anchors.right: parent.right
            anchors.left: parent.left
            text: "Logout"
            onClicked: {
                authManager.logoutUser(userEmail.text, userPassword.text)
            }
        }

        Rectangle{
            anchors.right: parent.right
            anchors.left: parent.left
            height: 10
            color: authManager.loggedIn === "" ? "red" : "green"
        }

        Button{
            anchors.right: parent.right
            anchors.left: parent.left
            text: "Refresh"
            onClicked: {
                authManager.refreshAccessToken()
            }
        }

        Button{
            anchors.right: parent.right
            anchors.left: parent.left
            text: "Get test data"
            onClicked: {
                authManager.getTestData();
            }
        }
    }
}
