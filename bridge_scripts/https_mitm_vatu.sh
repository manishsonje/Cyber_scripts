#!/bin/bash

openssl req -x509 -newkey rsa:2048 -keyout /tmp/keyvatu.pem -out /tmp/certvatu.pem -days 365 -nodes
openssl s_server -key /tmp/keyvatu.pem -cert /tmp/certvatu.pem -accept 44331
