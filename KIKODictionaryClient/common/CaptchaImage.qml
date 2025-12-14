import QtQuick

Rectangle {
    height:  70 // Dostosuj do wysokości CAPTCHA
    anchors.right: parent.right
    anchors.left: parent.left
    color: authManager.captcha.captchaImageUrl ? "transparent" : "#e0e0e0"
    border.color: "gray"

    Image {
        id: captchaImage
        anchors.fill: parent
        anchors.margins: 1
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
        text: authManager.captcha.captchaImageUrl ? "" : "Click 'Get captcha'"
        visible: !captchaImage.visible
    }
}
