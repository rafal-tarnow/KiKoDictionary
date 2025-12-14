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

    header: Text{
        text:"TEST LOGIN:"
        bottomPadding: 30
    }

    LoginComponent{
        anchors.right: parent.right
        anchors.left: parent.left
    }
}
