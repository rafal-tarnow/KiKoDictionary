## Run


Development enviroment run:
source .venv/bin/activate

uvicorn main:app --host 0.0.0.0 --port 8003 \
  --ssl-keyfile /home/rafal/fastapi_ssl/server.key \
  --ssl-certfile /home/rafal/fastapi_ssl/server.crt
  
## Deploy server

## Add new package
source .venv/bin/activate



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

## Install and Configure migrations
1. source .venv/bin/activate
2. pip install alembic
3. alembic init migrations
4. edit file alembic.init and change:
from:
#sqlalchemy.url = driver://user:pass@localhost/dbname
to:
sqlalchemy.url = sqlite:///./sentences.db
5. edit file: alembic/env.py
change line from:
target_metadata = None
to:
import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from database import Base
from models.sentence import Sentence
target_metadata = Base.metadata
6. alembic revision --autogenerate -m "Add user_id to sentences and migrate data"

### Wygenerowanie nowej migracji dla utworzenia tabeli  user_profiles
krok 1. source .venv/bin/activate
krok 2. jezeli utworzono nowa tabele w modelach to w pliku migrations/env.py dodać linie from src.db.models.user_profile import UserProfile
, w tym pliku dodajemy wszyskie importy z tabelami zeby alembic wiedzial jakie tabele sa potrzebne
krok 3. alembic revision --autogenerate -m "Add dual 
language support"
krok 4. przejrzec plik migracji czy wszystko dobrze cat ./migrations/versions/872780760451_add_user_profile_table_with_user_native_.py
krok 5. zastosowac migracje:  run alembic upgrade head