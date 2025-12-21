// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause


// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// Window {
//     id: root

//     visible: true

//     width: 450
//     height: 700

//     //width: Screen.width
//     //height: Screen.height

//     // Image{
//     // anchors.fill: parent
//     // source: "https://as1.ftcdn.net/v2/jpg/04/97/31/24/1000_F_497312401_fmQQiKYB8QsgZNsdXveTMLLYvMwe3lV9.jpg"
//     // }

//     Loader{
//     anchors.fill: parent
//     asynchronous: true
//     source: "http://127.0.0.1/View.qml"
//     }
// }




pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtExampleStyle

import "../health_page"
import "../register_page"
import "../captcha_page"
import "../login_page"

Window {
    id: window
    width: 450
    height: 700
    visible: true
    title: qsTr("Color Palette Client")

    enum DataView {
        UserView = 0,
        ColorView = 1
    }

    function hideAll(){
        serverSelectionPage.visible = false;
        colorview.visible = false;
        sentencesGui.visible = false;
        servicesHealthPage.visible = false
        registerPage.visible = false
        loginDbgPage.visible = false
        captchaPage.visible = false
    }

    Action {
        id: navigateBackAction
        icon.source: "qrc:/qt/qml/ColorPalette/assets/images/navi-drawer-svgrepo-com.svg"
        icon.width: 20
        icon.height: 20
        onTriggered: {
            drawer.open()
        }
    }

    LoginDialog{
        id: loginDialog
    }
    LoginRegisterDialog{
        id: loginRegisterDialog
    }

    ListModel {
        id: pagesModel
        ListElement {
            title: "Server selection"
        }
        ListElement {
            title: "Color View"
        }
        ListElement {
            title: "Sentences"
        }
        ListElement {
            title: "Dbg health"
        }
        ListElement {
            title: "Dbg register"
        }
        ListElement {
            title: "Dbg login"
        }
        ListElement{
            title: "Dbg captcha"
        }
    }

    Action {
        id: optionsMenuAction
        //icon.name: "menu"
        onTriggered: optionsMenu.open()
    }

    Rectangle{
        color: "#ff8888"
        anchors.horizontalCenter: parent.horizontalCenter
        width: window.width > 500 ? 500 : window.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        border.width: 1
        border.color: "blue"

        ToolBar {
            id: menuBar
            anchors.margins: 1
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            z: 2
            RowLayout{
                spacing: 20
                anchors.fill: parent

                ToolButton {
                    action: navigateBackAction
                    visible: true
                }
                Item{
                    Layout.fillHeight: true
                    Layout.fillWidth: true
               }
                RoundButton{
                    id: userButton
                    Layout.fillHeight: true
                    Layout.preferredWidth: menuBar.background.height
                    icon.source: authManager.loggedIn ? "qrc:/qt/qml/ColorPalette/assets/images/user_logged.svg" : "qrc:/qt/qml/ColorPalette/assets/images/user.svg"
                    icon.color: "transparent"
                    icon.height: userButton.height * 0.7
                    icon.width: userButton.height * 0.7
                    padding: 0
                    onClicked: {
                        loginDialog.open()
                        //loginRegisterDialog.open()
                    }
                    background: null
                }
                ToolButton{
                    action: optionsMenuAction
                    Menu {
                        id: optionsMenu
                        x: parent.width - width
                        transformOrigin: Menu.TopRight

                        Action {
                            text: qsTr("Settings")
                            //onTriggered: settingsDialog.open()
                        }
                        Action {
                            text: qsTr("Help")
                            //onTriggered: window.help()
                        }
                        Action {
                            text: qsTr("About")
                            //onTriggered: aboutDialog.open()
                        }
                        Action{
                            text: qsTr("Logout")
                            onTriggered: authManager.logoutUser()
                        }
                    }

                }
            }
            background: Rectangle{
                color: UIStyle.colorPrimary
                border.width: 1
                border.color: "yellow"
            }
        }

        ServerSelection {
            id: serverSelectionPage
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: true
            onServerSelected: {
                 colorview.visible = true;
                 sentencesGui.visible = false;
                 serverSelectionPage.visible = false
                console.log("QML on ServerSelection !!!")
                if(serverSelectionPage.visible === true){
                    hideAll();
                    colorview.visible = true
                }
            }
            colorResources: colors
            restPalette: paletteService
            colorUsers: users

            // onSentencesUrlChanged: {
            //     console.log("Captcha_url = " + serverSelectionPage.captchaUrl )
            //     console.log("Users_url = " + serverSelectionPage.usersUrl )
            //     console.log("Sentences_url = " + serverSelectionPage.sentencesUrl )

            // }

            onUsersUrlChanged: {
                console.log("Users_url = " + serverSelectionPage.usersUrl )

                authManager.baseUrl = serverSelectionPage.usersUrl
            }

            Component.onCompleted: {
                authManager.baseUrl = serverSelectionPage.usersUrl
            }

        }

        ColorView {
            id: colorview
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: false
            loginService: colorLogin
            colors: colors
            colorViewUsers: users
        }

        Sentences {
            id: sentencesGui
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: false
            colors: colors
            sentences: sentences
        }

        ServicesHealthPage{
            id: servicesHealthPage
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: false
        }

        RegisterPage{
            id: registerPage
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: false
        }

        LoginTestPage{
            id: loginDbgPage
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: false
        }

        CaptchaPage{
            id: captchaPage
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: false
        }
    }

    Drawer{
        id: drawer
        width: 200
        height: parent.height

        ListView {
            id: listView
            anchors.fill: parent
            model: pagesModel
            delegate: ItemDelegate{
                id: delegateItem
                required property string title
                width: listView.width
                text: title
                highlighted: ListView.isCurrentItem

                onClicked: {
                    hideAll();
                    if (title === "Server selection") {
                        serverSelectionPage.visible = true
                    } else if (title === "Color View") {
                        colorview.visible = true
                    } else if (title === "Sentences") {
                        sentencesGui.visible = true
                    } else if (title === "Dbg health") {
                        servicesHealthPage.visible = true
                    } else if (title === "Dbg register") {
                        registerPage.visible = true
                    } else if (title === "Dbg login") {
                        loginDbgPage.visible = true
                    } else if (title === "Dbg captcha"){
                        captchaPage.visible = true
                    }

                    drawer.close()
                }
            }
        }
     }




    //! [RestService QML element]
    RestService {
        id: paletteService

        PaginatedResource {
            id: users
            path: "users"
        }

        PaginatedResource {
            id: sentences
            path: "sentences/"
        }

        PaginatedResource {
            id: colors
            path: "unknown"
        }

        BasicLogin {
            id: colorLogin
            loginPath: "login"
            logoutPath: "logout"
        }
    }
    //! [RestService QML element]

}



