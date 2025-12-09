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

        Text{
            text:"CAPTCHA:"

            Component.onCompleted: {
                // Pobierz captchę przy wejściu na stronę
                authManager.captcha.fetchCaptcha()
            }
        }

        Rectangle {
            height:  100 // Dostosuj do wysokości CAPTCHA
            anchors.right: parent.right
            anchors.left: parent.left
            color: authManager.captcha.captchaImageUrl ? "transparent" : "#e0e0e0"
            border.color: "gray"

            Image {
                id: captchaImage
                anchors.centerIn: parent
                source: authManager.captcha.captchaImageUrl // QML Image obsługuje data URL base64
                fillMode: Image.PreserveAspectFit
                visible: authManager.captcha.captchaImageUrl !== ""

                Component.onCompleted: {
                    console.log("Image source trying to load: " + authManager.captcha.captchaImageUrl)
                }
                onStatusChanged: {
                    if (status === Image.Error) {
                        console.error("Error loading image:", source)
                    } else if (status === Image.Ready) {
                        console.log("Image loaded successfully:", source)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                text: authManager.captcha.captchaImageUrl ? "" : "Click 'Get CAPTCHA'"
                visible: !captchaImage.visible
            }
        }

        Button{
            anchors.right: parent.right
            anchors.left: parent.left
            text: qsTr("Get captcha")
            enabled: !authManager.captcha.isLoading
            onClicked: authManager.captcha.fetchCaptcha()
        }

        TextField {
            id: captchaText
            anchors.right: parent.right
            anchors.left: parent.left
            placeholderText: qsTr("captcha")
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

            Connections{
                target: authManager
                function onError(error){
                    console.log("QML ERROR " + error)
                    errorDialog.errorText = error
                    errorDialog.open()
                }
            }
        }

    }
}
