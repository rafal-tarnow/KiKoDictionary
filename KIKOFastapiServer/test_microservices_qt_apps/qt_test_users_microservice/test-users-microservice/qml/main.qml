import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 500
    height: 650
    title: "User Service Tester"

    Page{
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.verticalCenter
        header: Text{
            text: "Register"
        }
        contentItem: Column{
            TextField { id: regUsername; placeholderText: "Username"}
            TextField { id: regEmail; placeholderText: "Email"}
            TextField { id: regPassword; placeholderText: "Password"; echoMode: TextInput.Password }
            Label { text: "CAPTCHA Verification"; font.bold: true }
            Button {
                text: "Get new CAPTCHA"
                enabled: !userClient.isLoading
                onClicked: userClient.fetchCaptcha()
            }
            Image {
                //Layout.fillWidth: true
                height: 80
                source: userClient.captchaImageUrl
                fillMode: Image.PreserveAspectFit
            }
            TextField { id: regCaptchaAnswer; placeholderText: "Enter CAPTCHA text"; Layout.fillWidth: true }

            Button {
                text: "Register"
                highlighted: true
                enabled: !userClient.isLoading
                onClicked: userClient.registerUser(regUsername.text, regEmail.text, regPassword.text, regCaptchaAnswer.text)
            }
        }
    }

    // // Główny przełącznik widoku: zalogowany vs. niezalogowany
    // StackLayout {
    //     id: mainStack
    //     anchors.fill: parent
    //     currentIndex: userClient.isLoggedIn ? 1 : 0

    //     // --- Widok 0: Niezalogowany (Rejestracja/Logowanie) ---
    //     TabView {
    //         id: authTabs

    //         // --- Zakładka Rejestracji ---
    //         Tab {
    //             title: "Register"

    //             Flickable {
    //                 contentHeight: registerColumn.implicitHeight
    //                 anchors.fill: parent
    //                 clip: true

    //                 ColumnLayout {
    //                     id: registerColumn
    //                     width: parent.width - 20
    //                     anchors.horizontalCenter: parent.horizontalCenter
    //                     anchors.top: parent.top
    //                     anchors.topMargin: 10
    //                     spacing: 10

    //                     TextField { id: regUsername; placeholderText: "Username"; Layout.fillWidth: true }
    //                     TextField { id: regEmail; placeholderText: "Email"; Layout.fillWidth: true }
    //                     TextField { id: regPassword; placeholderText: "Password"; echoMode: TextInput.Password; Layout.fillWidth: true }

    //                     // Sekcja CAPTCHA
    //                     Label { text: "CAPTCHA Verification"; font.bold: true }
    //                     Button {
    //                         text: "Get new CAPTCHA"
    //                         Layout.fillWidth: true
    //                         enabled: !userClient.isLoading
    //                         onClicked: userClient.fetchCaptcha()
    //                     }
    //                     Image {
    //                         Layout.fillWidth: true
    //                         height: 80
    //                         source: userClient.captchaImageUrl
    //                         fillMode: Image.PreserveAspectFit
    //                     }
    //                     TextField { id: regCaptchaAnswer; placeholderText: "Enter CAPTCHA text"; Layout.fillWidth: true }

    //                     Button {
    //                         text: "Register"
    //                         Layout.fillWidth: true
    //                         highlighted: true
    //                         enabled: !userClient.isLoading
    //                         onClicked: userClient.registerUser(regUsername.text, regEmail.text, regPassword.text, regCaptchaAnswer.text)
    //                     }
    //                 }
    //             }
    //         }

    //         // --- Zakładka Logowania ---
    //         Tab {
    //             title: "Login"

    //             ColumnLayout {
    //                 width: parent.width - 20
    //                 anchors.centerIn: parent
    //                 spacing: 10

    //                 TextField { id: loginUsername; placeholderText: "Username"; Layout.fillWidth: true }
    //                 TextField { id: loginPassword; placeholderText: "Password"; echoMode: TextInput.Password; Layout.fillWidth: true }

    //                 Button {
    //                     text: "Login"
    //                     Layout.fillWidth: true
    //                     highlighted: true
    //                     enabled: !userClient.isLoading
    //                     onClicked: userClient.loginUser(loginUsername.text, loginPassword.text)
    //                 }
    //             }
    //         }
    //     }

    //     // --- Widok 1: Zalogowany ---
    //     ColumnLayout {
    //         id: loggedInView
    //         anchors.fill: parent
    //         anchors.margins: 10
    //         spacing: 10

    //         Label {
    //             text: "Logged In!"
    //             font.pointSize: 18
    //             font.bold: true
    //             Layout.alignment: Qt.AlignHCenter
    //         }

    //         TextArea {
    //             id: userInfoArea
    //             Layout.fillWidth: true
    //             Layout.fillHeight: true
    //             readOnly: true
    //             text: userClient.currentUserInfo
    //             font.family: "monospace"
    //         }

    //         Button {
    //             text: "Refresh My Info"
    //             enabled: !userClient.isLoading
    //             Layout.fillWidth: true
    //             onClicked: userClient.fetchCurrentUserInfo()
    //         }

    //         Button {
    //             text: "Logout"
    //             enabled: !userClient.isLoading
    //             Layout.fillWidth: true
    //             onClicked: userClient.logoutUser()
    //         }
    //     }
    // }

    // Pasek statusu na dole
    footer: Frame {
        background: Rectangle { color: "#f0f0f0" }
        Label {
            id: statusLabel
            text: userClient.isLoading ? "Loading..." : userClient.statusMessage
            anchors.fill: parent
            anchors.margins: 5
            wrapMode: Text.WordWrap
            color: userClient.statusMessage.startsWith("ERROR:") ? "red" : "darkgreen"
        }
    }
}
