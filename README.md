# Setup a aws E2 Ubuntu 16.04 Ruby
Setup a aws E2 Ubuntu 16.04 server with
Ruby, Ruby on Rails, NodJS, yarn, PostgreSQL,
Nginx, Passenger, imagemagick, jpegoptim, optipng

# Script setup
[setup.sh - Script file](setup.sh)

## Copy file to server
```
SETUP_IP=8.8.8.8
CERT=/.ssh/CERT.pem
SORCE=https://raw.githubusercontent.com/getonewin/server-setup/master/setup.sh
```

```
scp -i ~$SETUP_IP $SORCE ubuntu@$SETUP_IP:~
```

## SSH TO SERVER
```
ssh -i ~$SETUP_IP ubuntu@$SETUP_IP
```

### Run script
```
chmod +x setup.sh
sudo ./setup.sh
```

### Setup key
```
ssh-keygen -t rsa -C $SERVER_NAME@$SERVER_DOMAIN"
cat ~/.ssh/id_rsa.pub"
And add the deploy key to gitlab/github"
```

### SETUP SSL KEY (IF HTTPS)
```
sudo mkdir /etc/nginx/ssl"
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt"
```

# Restart the server @ AWS

## Start server
```
sudo service nginx start
sudo service nginx restart
```