#!/bin/sh

openssl genrsa -des3 -out ca.key  4096
cp ca.key password.ca.key
openssl rsa -in password.ca.key -out ca.key
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=CA/ST=Toronto/O=Parking Boxx/OU=EU/CN=Parking Boxx CA 10 years/emailAddress=admin@parkingboxx.com/"

#Create one year Server Key, CSR, and Self Signed Certificate
openssl genrsa -des3 -out server.key 1024
cp server.key password.server.key
openssl rsa -in password.server.key -out server.key
openssl req -new -key server.key -out server.csr -subj "/C=CA/ST=Toronto/O=Parking Boxx/OU=Sync Server/CN=dev-sync.parkingboxx.com/emailAddress=admin@parkingboxx.com/"

openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
cat ./server.crt ./ca.crt > ./all.crt

