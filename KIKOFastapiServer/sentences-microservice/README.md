## Run


Development enviroment run:

uvicorn main:app --host 192.168.0.129 --port 8000 \
  --ssl-keyfile /home/rafal/fastapi_ssl/server.key \
  --ssl-certfile /home/rafal/fastapi_ssl/server.crt
  
## Deploy server

Jak dostac sie na serwer?
1. Polacz sie z siecia lokalna wifi w ktorej jest serwer
2. Otworz PCMan-Qt
3. Otworz lacze w pasku adresu:  sftp://rafal@mojserver.local/home/rafal/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer/sentences-microservice
4. Podaj haslo
5. otowrzyc przegladarke i adres https://ssh.rafal-kruszyna.org
6. podac haslo


Install systemd service:
sudo cp ./deploy_files/kiko-sentences.service /etc/systemd/system/kiko-sentences.service


cat /etc/systemd/system/kiko-sentences.service

Systemd service
sudo systemctl status kiko-sentences.service
sudo systemctl start kiko-sentences.servicesudo 
sudo systemctl restart kiko-sentences.service
