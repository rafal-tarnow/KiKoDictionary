import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QtExampleStyle

import "../common"

ColumnLayout {
    spacing: 20
    Label {
        elide: Label.ElideRight
        text: qsTr("Please enter the credentials:")
        Layout.fillWidth: true
    }
    TextField {
        id: emailText
        focus: true
        placeholderText: qsTr("email")
        Layout.fillWidth: true
    }
    TextField {
        id: passwordText
        placeholderText: qsTr("password")
        echoMode: TextField.PasswordEchoOnEdit
        Layout.fillWidth: true
    }
    CaptchaComponent{
        Layout.fillWidth: true
    }
    Button{
        id: loginButton
        Layout.fillWidth: true
        text: qsTr("Login")
        buttonColor: "#2CDE85"
        textColor: "#FFFFFF"
        onClicked: {
            authManager.loginUser(emailText.text, passwordText.text)
        }
        Connections{
            target: authManager
            function onLoginSuccess(success){
                emailText.clear()
                passwordText.clear()
            }
        }
    }
}
