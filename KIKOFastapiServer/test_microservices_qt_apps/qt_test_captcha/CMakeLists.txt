cmake_minimum_required(VERSION 3.16)
project(CaptchaQtTester LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Network)

qt_add_executable(CaptchaQtTester
    main.cpp
    captchaclient.h
    captchaclient.cpp
)

# Dodaj folder qml jako zasób
qt_add_qml_module(CaptchaQtTester
    URI "Tester"
    VERSION 1.0
    QML_FILES
    qml/main.qml
    SOURCES auth_service/AuthManager.hpp
    SOURCES auth_service/AuthManager.cpp
    QML_FILES qml/auth_service/AuthPage.qml
    QML_FILES qml/auth_service/AuthLoginPage.qml
    QML_FILES qml/common/ScrollablePage.qml
    QML_FILES qml/auth_service/AuthRegisterPage.qml
)

target_link_libraries(CaptchaQtTester PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Network
)

# Instalacja (opcjonalne, ale dobre dla deploymentu)
install(TARGETS CaptchaQtTester
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
