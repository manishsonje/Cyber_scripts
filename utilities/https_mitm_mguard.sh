#!/bin/bash

openssl req -x509 -newkey rsa:2048 -keyout /tmp/key.pem -out /tmp/cert.pem -days 365 -nodes
openssl s_server -key /tmp/key.pem -cert /tmp/cert.pem -accept 44330
