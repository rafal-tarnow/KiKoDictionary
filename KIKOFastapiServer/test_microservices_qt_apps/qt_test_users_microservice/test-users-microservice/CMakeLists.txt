cmake_minimum_required(VERSION 3.16)
project(UserTester LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Network)

qt_add_executable(UserTester
    main.cpp
    userserviceclient.h
    userserviceclient.cpp
)

# Dodaj folder qml jako zasób
qt_add_qml_module(UserTester
    URI "Tester"
    VERSION 1.0
    QML_FILES
        qml/main.qml
)

target_link_libraries(UserTester PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Network
)

install(TARGETS UserTester
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
