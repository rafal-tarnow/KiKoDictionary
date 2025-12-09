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
        serverview.visible = false;
        colorview.visible = false;
        sentencesGui.visible = false;
        servicesHealthPage.visible = false
        registerPage.visible = false
        captchaPage.visible = false
    }

    Action {
        id: navigateBackAction
        icon.source: "qrc:/qt/qml/ColorPalette/icons/navi-drawer-svgrepo-com.svg"
        icon.width: 20
        icon.height: 20
        onTriggered: {
            drawer.open()
        }
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
        ListElement{
            title: "Dbg captcha"
        }
    }


    Rectangle{
        color: "#ff8888"
        anchors.horizontalCenter: parent.horizontalCenter
        width: window.width > 500 ? 500 : window.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom

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
            }
            background: Rectangle{
                color: UIStyle.colorPrimary
            }
        }

        ServerSelection {
            id: serverview
            anchors.margins: 1
            anchors.top: menuBar.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            visible: true
            onServerSelected: {
                 colorview.visible = true;
                 sentencesGui.visible = false;
                 serverview.visible = false
                console.log("QML on ServerSelection !!!")
                if(serverview.visible === true){
                    hideAll();
                    colorview.visible = true
                }
            }
            colorResources: colors
            restPalette: paletteService
            colorUsers: users
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
                        serverview.visible = true
                    } else if (title === "Color View") {
                        colorview.visible = true
                    } else if (title === "Sentences") {
                        sentencesGui.visible = true
                    } else if (title === "Dbg health") {
                        servicesHealthPage.visible = true
                    } else if (title === "Dbg register") {
                        registerPage.visible = true
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



