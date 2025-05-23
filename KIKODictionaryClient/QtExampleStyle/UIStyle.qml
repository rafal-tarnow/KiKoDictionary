// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma Singleton

import QtQuick

QtObject {
    id: uiStyle

    // Font Sizes
    readonly property int fontSizeXXS: 10
    readonly property int fontSizeXS: 15
    readonly property int fontSizeS: 20
    readonly property int fontSizeM: 25
    readonly property int fontSizeL: 30
    readonly property int fontSizeXL: 35
    readonly property int fontSizeXXL: 40

    // Color Scheme
    // Green
    readonly property color colorQtPrimGreen: "#41cd52"
    readonly property color colorQtAuxGreen1: "#21be2b"
    readonly property color colorQtAuxGreen2: "#17a81a"


    readonly property color colorAccent: "#ff99c8" //różowy
    readonly property color colorSecondary_2: "#fcf6bd" //żółty
    readonly property color colorGreen: "#d0f4de" //green
    readonly property color colorSecondary: "#a9def9" //blue
    readonly property color colorPrimary: "#00a884" //purple


    function iconPath(baseImagePath) {
        return `qrc:/qt/qml/ColorPalette/icons/${baseImagePath}.svg`
    }
}

