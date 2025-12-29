# How to setup development enviroment and build

## Client

Open Qt Creator (6.9.1), open KIKODictionary Client CMake project, configure Qt Creator project as webassembly, android and desktop app, and run as normal Qt project 

## Server

Open server forlder in Visual Studio Code and selecto foloder with microservice , then read README.md for microservice

# How to run microservices on production

Pobierz repozytorium, wejdz do katalogu z mikroserwisami, wykonaj skrypt:
(skrypt doda uslugi systemowe systemd, oraz skonfiguruje srodowiska
virtualne pip oraz poetry)

chmod +x install_maia_systemd_microservices.sh
./install_maia_systemd_microservices.sh

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

## IP serwera w sieci lokalnej
192.168.0.117

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



## 🛠️ Development Lokalny (Uruchomienie wielu serwisów)

Ten projekt składa się z kilku mikroserwisów. Aby uniknąć ręcznego uruchamiania każdego z nich w osobnych terminalach, używamy narzędzia **Honcho** (Pythonowy port Foremana), które zarządza procesami na podstawie pliku `Procfile`.

### 1. Wymagania wstępne

Upewnij się, że masz zainstalowane `pipx` (do izolacji narzędzi) oraz samo `honcho`:

```bash
# Instalacja honcho (jeśli jeszcze nie masz)
pipx install honcho

Instalacja zależności
Zanim uruchomisz serwisy po raz pierwszy, musisz przygotować ich środowiska wirtualne:

# Serwis Captcha (standardowy venv)
cd captcha-microservice
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

# Serwis Sentences (standardowy venv)
cd sentences-microservice
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

# Serwis Users (Poetry)
cd users-microservice
poetry install
cd ..

3. Uruchamianie (Start Serwisów)
Będąc w głównym katalogu projektu, uruchom jedną komendę:

cd KIKOFastapiServer
honcho start

Co się wtedy dzieje?
Honcho odczytuje plik Procfile i uruchamia wszystkie mikroserwisy jednocześnie, każdy na dedykowanym porcie. Logi ze wszystkich serwisów są strumieniowane do jednej konsoli (oznaczone różnymi kolorami).

Serwis	Technologia	Port Lokalny	URL
Captcha	FastAPI + venv	8001	http://localhost:8001
Sentences	FastAPI + venv	8002	http://localhost:8002
Users	FastAPI + Poetry	8003	http://localhost:8003
Aby zatrzymać wszystkie serwisy, po prostu naciśnij Ctrl + C w terminalu.



