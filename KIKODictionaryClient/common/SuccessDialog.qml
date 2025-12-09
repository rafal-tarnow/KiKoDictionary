import QtQuick
import QtQuick.Controls

Dialog {
    property alias errorText: contentText.text
    standardButtons: Dialog.Close
    title: qsTr("Success")
    contentItem: Text{
        id: contentText
        text: "Error"
        wrapMode: Text.Wrap
    }
}
