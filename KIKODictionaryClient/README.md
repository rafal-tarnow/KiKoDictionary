## Otwarcie stronki

Lokalnie:
http://192.168.0.117/
http://192.168.0.117/dudu/

## Pre kompresja zamiast kompresji w locie
cd /var/www/dudu/
sudo gzip -k -9 dudu.wasm

## Deploy Webassembly

1. Polacz sie z siecia lokalna wifi w ktorej jest serwer
2. Otworz PCMan-Qt
3. Otworz lacze w pasku adresu:  sftp://rafal@mojserver.local/home/rafal/Documents/dudu
4. Podaj haslo
5. skopiowac 5 plikow dudu.html dudu.js dudu.wasm qtloader.js qtlogo.svg
6. otowrzyc przegladarke i adres https://ssh.rafal-kruszyna.org
7. podac haslo
8. cd ~
9. ./install_dudu.sh
10. podac haslo
