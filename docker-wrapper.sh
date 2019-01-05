#!/bin/bash

# . /appenv/bin/activate
cd /home/docker
umask 0022
exec "$@"
