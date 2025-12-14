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


# Jak polaczayc sie z serwerem

## Polaczenie Lokalnie w tej samej sieci
Za pomoca terminala
ssh rafal@mojserver.local/home/rafal
sftp rafal@mojserver.local/home/rafal

Za pomoca PCMan-Qt
ssh://rafal@mojserver.local/home/rafal
sftp://rafal@mojserver.local/home/rafal

## Zdalnie Przez Interfejs WWW

https://ssh.rafal-kruszyna.org/

## Zdalne Polaczenie natywne przez tunel cloudflare

Zainstalowac i skonfigurowac klienta cloudflare i w terminalu:
(Install cloudflared on the client machine)
(nano ~/.ssh/config)
(Host ssh.rafal-kruszyna.org)
(ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h)

ssh rafal@ssh.rafal-kruszyna.org
sftp rafal@ssh.rafal-kruszyna.org

albo w PCMan-Qt w pasku adresu:
ssh://rafal@ssh.rafal-kruszyna.org
sftp://rafal@ssh.rafal-kruszyna.org

# Nextcloud
Na serwerze jest uruchomiona instancja nexcloud
https://rafal-kruszyna.org/nextcloud

