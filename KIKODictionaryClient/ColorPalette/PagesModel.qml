import QtQuick

ListModel {
    ListElement {
        title: qsTr("Colors")
        source: "qrc:/qt/qml/ColorPalette/pages/HomePage.qml"
    }
    ListElement {
        title: qsTr("Sentences")
        source: "qrc:/qt/qml/ColorPalette/pages/list_view/ListViewPage.qml"
    }
}
