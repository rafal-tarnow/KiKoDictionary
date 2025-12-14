import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../common"

ScrollablePage {
    id: page

    Component.onCompleted: {
        // Pobierz captchę przy wejściu na stronę
        authManager.captcha.fetchCaptcha()
    }

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

        CaptchaComponent{
            anchors.right: parent.right
            anchors.left: parent.left
        }

        Button{
            anchors.right: parent.right
            anchors.left: parent.left
            text: "Register"
            onClicked: {
                authManager.registerUser(userEmail.text, userName.text, userPassword.text, captchaText.text)
            }

            ErrorDialog{
                id: errorDialog
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                width: Math.min(page.width, page.height) / 3 * 2
            }

            SuccessDialog{
                id: successDialog
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                width: Math.min(page.width, page.height) / 3 * 2
            }

            Connections{
                target: authManager
                function onError(error){
                    console.log("QML ERROR " + error)
                    errorDialog.errorText = error
                    errorDialog.open()
                }
            }

            Connections{
                target: authManager
                function onRegisterSuccess(success){
                    console.log("QML Success " + success)
                    successDialog.successText = success
                    successDialog.open()
                }
            }
        }

    }
}
