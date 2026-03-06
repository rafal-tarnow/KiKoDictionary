import QtQuick
import QtQuick.Controls
// import ColorPalette

Page {

    ApiClient{
        id: apiClient
    }

    Rectangle{
        anchors.fill: parent
        color: "green"

        Column{
            Button{
                text: "Login"
                onClicked: {
                    console.log("clicked login !")
                    apiClient.login("ania@ania.com", "aina")
                }
            }
        }
    }
}
