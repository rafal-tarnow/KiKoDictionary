#!/bin/bash
sudo apt install python3-poetry
poetry config virtualenvs.in-project true
poetry install

sudo cp maia-users.service /etc/systemd/system/maia-users.service
