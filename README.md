# How to setup development enviroment and build

## Client

Open Qt Creator (6.9.1), open KIKODictionary Client CMake project, configure Qt Creator project as webassembly, android and desktop app, and run as normal Qt project 

## Server

Open server forlder in Visual Studio Code and selecto foloder with microservice , then read README.md for microservice

# KiKoDictionary


cd ~/Qt/
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk/
git pull
./emsdk install 3.1.70
./emsdk activate 3.1.70
source "/home/rafal/Qt/emsdk/emsdk_env.sh"
echo 'source "/home/rafal/Qt/emsdk/emsdk_env.sh"' >> $HOME/.bash_profile

