## Run


Development enviroment run:

uvicorn main:app --host 192.168.0.129 --port 8000 \
  --ssl-keyfile /home/rafal/fastapi_ssl/server.key \
  --ssl-certfile /home/rafal/fastapi_ssl/server.crt