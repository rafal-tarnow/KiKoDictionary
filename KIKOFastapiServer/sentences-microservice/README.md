## Run


Development enviroment run:
source .venv/bin/activate

uvicorn main:app --host 0.0.0.0 --port 8003 \
  --ssl-keyfile /home/rafal/fastapi_ssl/server.key \
  --ssl-certfile /home/rafal/fastapi_ssl/server.crt
  
## Deploy server





## How to install app on new server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd systemd_files
chmod +x install_systemd_service.sh
./install_systemd_service.sh
sudo systemctl enable --now maia-sentences.service

sudo systemctl start maia-sentences.service
sudo systemctl stop maia-sentences.service
sudo systemctl status maia-sentences.service
sudo systemctl restart maia-sentences.service
