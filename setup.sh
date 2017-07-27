#!/bin/bash
#
echo "###############################################################################"
echo "# Configuration"
echo "###############################################################################"

SEVER_TEYP="production" # OR sandbox/production
SERVER_DOMAIN="getonewin.com"
SERVER_COUNT="01"
SERVER_IP="35-158-118-163" # Not in use

SERVER_NAME="$SEVER_TEYP$SERVER_COUNT"

SERVER_HOST="$SERVER_NAME"
APP_NAME="onewin"
WWW_DIR="var/www"

RUBY_VERSION="2.4"
RUBY_VERSION_STRING="2.4.1"
RUBY_SOURCE_URL="https://ftp.ruby-lang.org/pub/ruby/$RUBY_VERSION/ruby-$RUBY_VERSION_STRING.tar.gz"
RUBY_SOURCE_TAR_NAME="ruby-$RUBY_VERSION_STRING.tar.gz"
RUBY_SOURCE_DIR_NAME="ruby-$RUBY_VERSION_STRING/"

RAILS_VERSION="5.1.2"

POSTGRESQL="9.6"

NODE_JS_VERSION="8"

echo "###############################################################################"
echo "SEVER_TEYP: $SEVER_TEYP"
echo "SERVER_NAME: $SERVER_NAME"
echo "APP_NAME: $APP_NAME"
echo "WWW_DIR: $WWW_DIR"
echo "---------------"
echo "INSTALL NODEJS v$NODE_JS_VERSION"
echo "INSTALL POSTGRESQL v$POSTGRESQL"
echo "INSTALL RUBY v$RUBY_VERSION"
echo "INSTALL RAILS v$RAILS_VERSION"
echo "###############################################################################"
echo "---------------"
echo "###############################################################################"
echo "# Sanity Checks"
echo "###############################################################################"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Must be run with root privileges."
  exit 1
fi

source /etc/lsb-release
if [ "$DISTRIB_ID" != "Ubuntu" -o "$DISTRIB_RELEASE" != "16.04" ]; then
  echo "ERROR: Only Ubuntu 16.04 is supported."
  exit 1
fi

read -p "Continue (y/n)?" CONT
if [ "$CONT" == "y" ]; then

  echo "###############################################################################"
  echo "# SETUP"
  echo "###############################################################################"

  sudo apt-get update -y --force-yes
  sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev -y --force-yes

  echo "###############################################################################"
  echo "# SETUP WWW DIR"
  echo "###############################################################################"

  sudo adduser ubuntu www-data
  sudo mkdir "/$WWW_DIR"
  sudo chown -R www-data:www-data "/$WWW_DIR"
  sudo chmod -R g+rwX "/$WWW_DIR"

  echo "##################### ##########################################################"
  echo "# Install Nodjs/yarn"
  echo "###############################################################################"

  curl -sL https://deb.nodesource.com/setup_$NODE_JS_VERSION.x | sudo -E bash -
  sudo apt-get install -y nodejs --force-yes

  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update
  sudo apt-get install yarn --force-yes

  echo "###############################################################################"
  echo "# RUBY"
  echo "###############################################################################"

  cd
  wget $RUBY_SOURCE_URL
  tar -xzvf $RUBY_SOURCE_TAR_NAME
  cd $RUBY_SOURCE_DIR_NAME
  ./configure
  make
  sudo make install
  ruby -v

  echo "###############################################################################"
  echo "# Bundler"
  echo "###############################################################################"

  echo "gem: --no-ri --no-rdoc" > ~/.gemrc
  sudo gem install bundler

  echo "###############################################################################"
  echo "# Rails"
  echo "###############################################################################"

  sudo gem install rails -v $RAILS_VERSION

  echo "###############################################################################"
  echo "# PostgreSQL"
  echo "###############################################################################"

  sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

  wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -

  sudo apt-get update -y --force-yes
  sudo apt-get install postgresql-common -y --force-yes
  sudo apt-get install postgresql-$POSTGRESQL libpq-dev -y --force-yes
  sudo apt-get install libpq-dev build-essential

  echo "###############################################################################"
  echo "# Nginx/Passenger"
  echo "###############################################################################"

  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
  sudo apt-get install -y apt-transport-https ca-certificates

  sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
  sudo apt-get update

  sudo apt-get install -y nginx-extras passenger

  # In order for Capistrano to create symlinks, it needs write permissions in the relevant directories. We can give them with the following commands:
  sudo chgrp www-data /etc/nginx/sites-enabled
  sudo chmod g+w /etc/nginx/sites-enabled

  sudo chgrp www-data /etc/init.d
  sudo chmod g+w /etc/init.d

  echo "##################### ##########################################################"
  echo "# Install imagemagick"
  echo "###############################################################################"

  sudo locale-gen en_US.UTF-8 -y --force-yes
  sudo dpkg-reconfigure locales -y --force-yes
  LANG=en_US.UTF-8

  sudo add-apt-repository main
  sudo add-apt-repository universe
  sudo apt-get update -y --force-yes
  sudo apt-get install imagemagick libmagickcore-dev libmagickwand-dev --fix-missing -y --force-yes

  echo "##################### ##########################################################"
  echo "# Install jpegoptim / optipng"
  echo "###############################################################################"

  sudo apt-get install jpegoptim -y --force-yes
  sudo apt-get install optipng -y --force-yes

  echo "##################### ##########################################################"
  echo "# Add nginx config "
  echo "###############################################################################"

  sudo rm /etc/nginx/nginx.conf
  sudo touch /etc/nginx/nginx.conf
  echo "user www-data;
worker_processes 4;
pid /run/nginx.pid;

events {
  worker_connections 768;
}

http {

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  # server_tokens off;
  client_max_body_size 300m;
  # server_names_hash_bucket_size 64;
  # server_name_in_redirect off;

  userid on;
  userid_name brid;
  userid_domain '$SERVER_DOMAIN';
  userid_path /;
  userid_expires max;
  userid_mark S;

  proxy_set_header X-Nginx-Browser-ID-Got $uid_got;
  proxy_set_header X-Nginx-Browser-ID-Set $uid_set;

  default_type application/octet-stream;

  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  ##
  # gzip Settings
  ##
  gzip on;
  gzip_disable \"msie6\";

  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_min_length 256;
  gzip_types text/plain text/css application/javascript image/svg+xml application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

  passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
  passenger_ruby /usr/local/bin/ruby;

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
" >> /etc/nginx/nginx.conf

  echo "##################### ##########################################################"
  echo "# Add nginx site config "
  echo "###############################################################################"

  sudo rm /etc/nginx/sites-enabled/default
  sudo touch /etc/nginx/sites-enabled/default

echo "server {
  listen 80 default_server;
  listen [::]:80 default_server ipv6only=on;

  listen 443 ssl default_server http2 default_server;
  listen [::]:443 default_server ssl http2 default_server;

  server_name $SERVER_DOMAIN;

  ssl_certificate /etc/nginx/ssl/nginx.crt;
  ssl_certificate_key /etc/nginx/ssl/nginx.key;

  # Media: images, icons, video, audio, HTC
  location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
    expires 1M;
    access_log off;
    add_header Cache-Control \"public\";
  }

  # CSS and Javascript
  location ~* \.(?:css|js)$ {
    expires 1y;
    access_log off;
    add_header Cache-Control \"public\";
  }

  passenger_enabled on;
  #passenger_min_instances 2;
  #passenger_intercept_errors on;
  # rails_env development; # IF YOU NEED TO RUN IT IN DEVELOPMENT
  rails_env    $SEVER_TEYP;

  root /$WWW_DIR/$APP_NAME/current/public;

  # redirect server error pages to the static page /50x.html
  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
    root   html;
  }
}
" >> /etc/nginx/sites-enabled/default

  echo "##################### ##########################################################"
  echo "# Capistrano - FIX - CLEANUP"
  echo "###############################################################################"

  # In order for Capistrano to create symlinks, it needs write permissions in the relevant directories. We can give them with the following commands:
  sudo chgrp www-data /etc/nginx/sites-enabled
  sudo chmod g+w /etc/nginx/sites-enabled

  sudo chgrp www-data /etc/init.d
  sudo chmod g+w /etc/init.d

  echo "##################### ##########################################################"
  echo "# Server settings"
  echo "###############################################################################"

  #sudo hostname $SERVER_HOST

  echo "##################### ##########################################################"
  echo "# SYSTEM - CLEANUP"
  echo "###############################################################################"

  sudo apt-get update -y --force-yes
  sudo apt-get autoremove -y --force-yes
  sudo apt-get clean -y --force-yes

  echo "###############################################################################"
  echo "# SERVER IS READY"
  echo "###############################################################################"
  echo "RAILS"
  rails -v
  echo "RUBY"
  ruby -v
  echo "POSTGRESQL"
  psql --version
  echo "NODEJS"
  nodejs -v
  echo "YARN"
  yarn -v

  echo "###############################################################################"
  echo "# YOU NEED TO RUN "
  echo "###############################################################################"
  echo "# SETUP KEY"
  echo "###############################################################################"
  echo "ssh-keygen -t rsa -C $SERVER_NAME@$SERVER_DOMAIN"
  echo "cat ~/.ssh/id_rsa.pub"
  echo "And add the deploy key to gitlab/github"
  echo "###############################################################################"
  echo "###############################################################################"
  echo "# SETUP SSL KEY"
  echo "###############################################################################"
  echo "sudo mkdir /etc/nginx/ssl"
  echo "sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt"
  echo "###############################################################################"

else
  echo "###############################################################################"
  echo "# NOTING HAPPEND "
  echo "###############################################################################"
fi