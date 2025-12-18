#!/bin/bash
USER=notuser
IP=192.168.1.120
DIR=Git/justworks
xbps-install -S
xbps-install -u xbps
xbps-install git
git clone $USER@$IP:$DIR
