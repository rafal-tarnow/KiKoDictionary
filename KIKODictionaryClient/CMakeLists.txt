# Copyright (C) 2023 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(KIKODictionaryClient LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

# Add SSL android support
if (ANDROID)
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
endif()


qt_add_executable(dudu
    main.cpp
)

set_target_properties(dudu PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

add_subdirectory(QtExampleStyle)

qt_add_qml_module(dudu
    URI ColorPalette
    QML_FILES
        ColorPalette/Main.qml
        ColorPalette/ServerSelection.qml
        ColorPalette/ColorView.qml
        ColorPalette/ColorDialogEditor.qml
        ColorPalette/ColorDialogDelete.qml
        ColorPalette/UserMenu.qml
        ColorPalette/PagesModel.qml
        ColorPalette/Sentences.qml
        ColorPalette/SentenceDialogEditor.qml
    SOURCES
        abstractresource.h
        basiclogin.h basiclogin.cpp
        restservice.h restservice.cpp
        paginatedresource.h paginatedresource.cpp
    RESOURCES
        icons/qt.png
        icons/testserver.png
        icons/userMask.svg
        icons/close.svg
        icons/delete.svg
        icons/dots.svg
        icons/edit.svg
        icons/login.svg
        icons/logout.svg
        icons/ok.svg
        icons/update.svg
        icons/user.svg
        icons/user_logged.svg
        icons/plus.svg
        icons/navi-drawer-svgrepo-com.svg
        qtquickcontrols2.conf
        QML_FILES ColorPalette/SentenceDialogDelete.qml
        QML_FILES common/ScrollablePage.qml
        QML_FILES health_page/ServicesHealthPage.qml
        SOURCES ServerMonitor.h
        SOURCES ServerMonitor.cpp
        SOURCES ServerMonitor.cpp
        SOURCES AuthManager.hpp
        SOURCES AuthManager.cpp
        QML_FILES register_page/RegisterPage.qml
        QML_FILES common/ErrorDialog.qml
        QML_FILES common/SuccessDialog.qml
        SOURCES CaptchaClient.hpp
        SOURCES CaptchaClient.cpp
        QML_FILES captcha_page/CaptchaPage.qml
        QML_FILES login_page/LoginTestPage.qml
        QML_FILES login_page/LoginDialog.qml
        QML_FILES login_page/LoginComponent.qml
        QML_FILES common/CaptchaImage.qml
        QML_FILES common/CaptchaComponent.qml
        QML_FILES login_page/LoginRegisterDialog.qml
)

# add SSL support for android
if (ANDROID)
    add_android_openssl_libraries(dudu)
endif()

qt_add_resources(dudu "assets"
    PREFIX
        "/"
    FILES
        assets/server.crt
)

target_link_libraries(dudu PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)


install(TARGETS dudu
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET dudu
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
