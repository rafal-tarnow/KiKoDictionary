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
            text:"CAPTCHA:"
        }

        Button {
            id: fetchButton
            text: "Get CAPTCHA"
            enabled: !captchaClient.isLoading
            onClicked: captchaClient.fetchCaptcha()
        }

        Rectangle {
            height:  100 // Dostosuj do wysokości CAPTCHA
            anchors.right: parent.right
            anchors.left: parent.left
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
            anchors.right: parent.right
            anchors.left: parent.left
            enabled: !captchaClient.isLoading && captchaClient.captchaImageUrl !== ""
        }

        Button {
            id: verifyButton
            text: "Verify CAPTCHA"
            anchors.right: parent.right
            anchors.left: parent.left
            enabled: !captchaClient.isLoading && captchaClient.captchaImageUrl !== "" && answerInput.text.length > 0
            onClicked: captchaClient.verifyCaptcha(answerInput.text)
        }

        Text {
            id: resultText
            anchors.right: parent.right
            anchors.left: parent.left
            text: captchaClient.isLoading ? "Loading..." : captchaClient.verificationResult
            wrapMode: Text.WordWrap
            font.bold: true
            color: captchaClient.verificationResult.startsWith("Result: VALID") ? "green" :
                                                                                  captchaClient.verificationResult.startsWith("Result: INVALID") ? "red" :
                                                                                                                                                   captchaClient.verificationResult.startsWith("Error:") ? "darkred" : "black"
        }
    }
}
