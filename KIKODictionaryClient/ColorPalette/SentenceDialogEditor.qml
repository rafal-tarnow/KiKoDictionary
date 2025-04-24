import QtQuick
import QtQuick.Controls

Dialog {

    padding: 10
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    standardButtons: Dialog.Ok | Dialog.Cancel

    function createNewSentence() {
        open()
    }
}
