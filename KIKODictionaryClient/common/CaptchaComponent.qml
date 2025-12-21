import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 15

    CaptchaImage{
        height:  70
        Layout.fillWidth: true
    }

    RowLayout{
        anchors.right: parent.right
        anchors.left: parent.left
        TextField {
            Layout.fillWidth: true
            id: captchaText
            placeholderText: qsTr("enter captcha")
        }
        Button{
            Layout.preferredWidth: height
            text: qsTr("reload")
            enabled: !authManager.captcha.isLoading
            onClicked: authManager.captcha.fetchCaptcha()
            icon.source: "qrc:/qt/qml/ColorPalette/assets/images/update.svg"
        }
    }
}
