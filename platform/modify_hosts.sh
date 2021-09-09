#!/bin/bash

proxy_ip=$(getent hosts "$PROXY_HOST" | awk '{ print $1 }')

echo "${proxy_ip} localhost" >> /etc/hosts