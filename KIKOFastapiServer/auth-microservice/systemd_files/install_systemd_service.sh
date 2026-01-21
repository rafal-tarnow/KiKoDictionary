#!/bin/bash
sudo apt install python3-poetry
poetry config virtualenvs.in-project true
poetry install

sudo cp maia-auth.service /etc/systemd/system/maia-auth.service
