import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./auth_service"
// import Tester 1.0 // Potrzebne, jeśli używasz qmlRegisterType i tworzysz obiekt CaptchaClient w QML

ApplicationWindow {
    visible: true
    width: 700
    height: 350
    title: "CAPTCHA Tester"

    // Jeśli CaptchaClient jest rejestrowany przez qmlRegisterType:
    // CaptchaClient {
    //     id: captchaClient
    // }
    // W tym przykładzie używamy setContextProperty, więc captchaClient jest dostępne globalnie.

    ColumnLayout {
        id: captchaPage
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width/3

        anchors.margins: 5
        spacing: 10

        Button {
            id: fetchButton
            text: "Get CAPTCHA"
            Layout.fillWidth: true
            enabled: !captchaClient.isLoading
            onClicked: captchaClient.fetchCaptcha()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100 // Dostosuj do wysokości CAPTCHA
            color: captchaClient.captchaImageUrl ? "transparent" : "#e0e0e0"
            border.color: "gray"

            Image {
                id: captchaImage
                anchors.centerIn: parent
                source: captchaClient.captchaImageUrl // QML Image obsługuje data URL base64
                fillMode: Image.PreserveAspectFit
                visible: captchaClient.captchaImageUrl !== ""

                Component.onCompleted: {
                    console.log("Image source trying to load: " + captchaClient.captchaImageUrl)
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
                text: captchaClient.captchaImageUrl ? "" : "Click 'Get CAPTCHA'"
                visible: !captchaImage.visible
            }
        }

        TextField {
            id: answerInput
            placeholderText: "Enter CAPTCHA text"
            Layout.fillWidth: true
            enabled: !captchaClient.isLoading && captchaClient.captchaImageUrl !== ""
        }

        Button {
            id: verifyButton
            text: "Verify CAPTCHA"
            Layout.fillWidth: true
            enabled: !captchaClient.isLoading && captchaClient.captchaImageUrl !== "" && answerInput.text.length > 0
            onClicked: captchaClient.verifyCaptcha(answerInput.text)
        }

        Text {
            id: resultText
            Layout.fillWidth: true
            text: captchaClient.isLoading ? "Loading..." : captchaClient.verificationResult
            wrapMode: Text.WordWrap
            font.bold: true
            color: captchaClient.verificationResult.startsWith("Result: VALID") ? "green" :
                   captchaClient.verificationResult.startsWith("Result: INVALID") ? "red" :
                   captchaClient.verificationResult.startsWith("Error:") ? "darkred" : "black"
        }
    }

    AuthRegisterPage{
        id: registerPage
        anchors.left: captchaPage.right
        anchors.right: loginPage.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 5
    }

    AuthLoginPage{
    id: loginPage
       anchors.top: parent.top
       anchors.bottom: parent.bottom
       anchors.right: parent.right
       width: parent.width/3
       anchors.margins: 5
    }
}
