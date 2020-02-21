#!/bin/bash

sudo cp secret.service /etc/systemd/system/
sudo systemctl start secret
