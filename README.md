# server-setup
Setup a aws E2 Ubuntu 16.04 server with
Ruby, Ruby on Rails, NodJS, yarn, PostgreSQL,
Nginx, Passenger, imagemagick, jpegoptim, optipng

# Script setup
[setup.sh - Script file](setup.sh)

#Copy file to server
```
SETUP_IP=8.8.8.8
CERT=/.ssh/CERT.pem
SORCE=https://raw.githubusercontent.com/getonewin/server-setup/master/setup.sh
```

```
scp -i ~$SETUP_IP $SORCE ubuntu@$SETUP_IP:~
```

# SSH TO SERVER
```
ssh -i ~$SETUP_IP ubuntu@$SETUP_IP
```

# Run script
```
chmod +x setup.sh
sudo ./setup.sh
```

# Restart the server @ AWS

# Start server
sudo service nginx start
sudo service nginx restart