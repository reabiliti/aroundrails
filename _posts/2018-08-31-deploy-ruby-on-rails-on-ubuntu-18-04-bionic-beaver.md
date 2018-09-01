---
layout: post
title:  "Deploy Ruby On Rails on Ubuntu 18.04 Bionic Beaver"
date:   2018-08-31 02:18:17 +0300
categories: Ruby Rails Ubuntu
---

# Introduction

We will be setting up a Ruby on Rails production environment on Ubuntu 18.04 LTS Bionic Beaver.

Since we setup Ubuntu for our development environment, we also want to use it in production. This keeps your application running consistently between development and production. We're using an LTS version of Ubuntu in production because it is supported for several years where a normal version of Ubuntu isn't.

First you need a clean system Ubuntu 18.04 Bionic Bever Server.

Also replace Ubuntu 18.04 Bionic default `/etc/apt/sources.list` for the [next list][sources.list].

```
sudo vim /etc/apt/sources.list
```

Content:

```
#deb cdrom:[Ubuntu 18.04 LTS _Bionic Beaver_ - Release amd64 (20180426)]/ bionic main restricted

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://us.archive.ubuntu.com/ubuntu/ bionic universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic universe
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu 
## team, and may not be under a free licence. Please satisfy yourself as to 
## your rights to use the software. Also, please note that software in 
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu bionic partner
# deb-src http://archive.canonical.com/ubuntu bionic partner

deb http://security.ubuntu.com/ubuntu bionic-security main restricted
# deb-src http://security.ubuntu.com/ubuntu bionic-security main restricted
deb http://security.ubuntu.com/ubuntu bionic-security universe
# deb-src http://security.ubuntu.com/ubuntu bionic-security universe
deb http://security.ubuntu.com/ubuntu bionic-security multiverse
# deb-src http://security.ubuntu.com/ubuntu bionic-security multiverse
```

Perform a system update.

```
sudo apt-get update
sudo apt-get upgrade
```
The first thing we will do on our new server is create the user account we'll be using to run our applications and work from there.

```
sudo adduser deploy
sudo adduser deploy sudo
su deploy
```

# Config run sudo command without a password

Backup your `/etc/sudoers` file by typing the following command:

```
sudo cp /etc/sudoers /root/sudoers.bak
```

Edit the `/etc/sudoers` file by typing the visudo command:

```
sudo visudo
```

Append the following entry to run ALL command without a password for a user named `deploy`:

```
deploy ALL=(ALL) NOPASSWD:ALL
```

Save and close the file. Now you can run any command as root user:

```
sudo systemctl restart nginx
sudo reboot
sudo apt-get install htop

## get root shell ##
sudo -i
```

# Config ssh acces via ssh-key

Before we move forward is that we're going to setup SSH to authenticate via keys instead of having to use a password to login. It's more secure and will save you time in the long run.

We're going to use `ssh-copy-id` to do this. If you're on OSX you may need to run `brew install ssh-copy-id` but if you're following this tutorial on Linux desktop, you should already have it.

Once you've got `ssh-copy-id` installed, run the following and replace IPADDRESS with the one for your server:

> Make sure you run ssh-copy-id on your computer, and NOT the server.

```
ssh-copy-id deploy@IPADDRESS
```

Now when you run `ssh deploy@IPADDRESS` you will be logged in automatically. Go ahead and SSH again and verify that it doesn't ask for your password before moving onto the next step.

> For the next steps, **make sure you are logged in as the deploy user on the server!**

# Installing Ruby

The first step is to install some dependencies for Ruby and Rails.

To make sure we have everything necessary for Webpacker support in Rails, we're first going to start by adding the Node.js and Yarn repositories to our system before installing them.

```
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get update
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn
```
Next we're going to be installing Ruby using one of three methods. Each have their own benefits, most people prefer using rbenv these days, but if you're familiar with rvm you can follow those steps as well. I've included instructions for installing from source as well, but in general, you'll want to choose either rbenv or rvm.

Choose one method. Some of these conflict with each other, so choose the one that sounds the most interesting to you, or go with my suggestion, rbenv.

Installing with rbenv is a simple two step process. First you install rbenv, and then ruby-build:

```
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 2.5.1
rbenv global 2.5.1
ruby -v
```

The last step is to install Bundler

```
gem install bundler
```

rbenv users need to run `rbenv rehash` after installing bundler.

# Installing Nginx

For our setup, we'll be using NGINX as our webserver to receive HTTP requests. Those requests will then be handed over to Passenger which will run our Ruby app.

Phusion is the company that develops Passenger and they recently put out an official Ubuntu package that ships with Nginx and Passenger pre-installed.

We'll be using that to setup our production server because it's very easy to setup.

```
sudo apt-get install -y dirmngr gnupg
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates

sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update

sudo apt-get install -y nginx-extras libnginx-mod-http-passenger

if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then sudo ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi
sudo ls /etc/nginx/conf.d/mod-http-passenger.conf
```

So now we have Nginx and passenger installed. We can manage the Nginx webserver by using the systemd:

```
sudo systemctl start nginx
```

To check and make sure your Passenger install is configured correctly, run the following command:

```
sudo /usr/bin/passenger-config validate-install
```

Open up the server's IP address in your browser to make sure that nginx is up and running.

The `systemctl` command also provides some other methods such as `restart` and `stop` that allow you to easily restart and stop your webserver.

Next, we need to update the Nginx configuration to point Passenger to the version of Ruby that we're using. You'll want to open up `/etc/nginx/conf.d/mod-http-passenger.conf` in your favorite editor. I like to use `vim`, so I'd run this command:

```
sudo vim /etc/nginx/conf.d/mod-http-passenger.conf

# You could also use nano if you don't like vim
# sudo nano /etc/nginx/conf.d/mod-http-passenger.conf
```

And change the passenger_ruby line to point to your ruby executable:

```
passenger_ruby /home/deploy/.rbenv/shims/ruby; # If you use rbenv
# passenger_ruby /home/deploy/.rvm/wrappers/ruby-2.1.2/ruby; # If use use rvm, be sure to change the version number
# passenger_ruby /usr/bin/ruby; # If you use ruby from source
```

The `passenger_ruby` is the important line here. Make sure you only set this once and use the line from the example that pertains to the version of Ruby you installed.

Once you've changed `passenger_ruby` to use the right version Ruby, you can run the following command to restart Nginx with the new Passenger configuration.

```
sudo systemctl restart nginx
```

Now that we've restarted Nginx, the Rails application will be served up using the deploy user just how we want. In the Capistrano section we will talk about configuring Nginx to serve up your Rails application.

# Installing PostgreSQL

Postgres 10.5 is available in the Ubuntu repositories and we can install it like so:

```
sudo apt-get install postgresql postgresql-contrib libpq-dev
```

Next we need to setup our postgres user (also named "deploy" but different from our linux user named "deploy") and database:

```
sudo su - postgres
createuser --pwprompt deploy
createdb -O deploy my_app_name_production # change "my_app_name" to your app's name which we'll also use later on
exit
```
The password you type in here will be the one to put in your `my_app/current/config/database.yml` later when you deploy your app for the first time.

# Capistrano Setup

> For Capistrano, **make sure you do these steps on your development machine inside your Rails app.**

Capistrano is a Ruby library that we'll use to deploy our code to our production server. It will maintain a copy of our git repo on the server and a set of release folders. Each release is a copy of our app whenever it was deployed and we'll have a current symlink that will be what's running in production. That will point to which release is currently running and allow us to easily rollback to previous releases should something go wrong.

The first step is to add Capistrano to your `Gemfile`:

```
gem 'capistrano'
gem 'capistrano-rails'
gem 'capistrano-passenger'
gem 'capistrano-rbenv'
gem 'capistrano-bundler'
```

Once these are added, run the following command to generate your capistrano configuration.

```
cap install STAGES=production
```

Next we need to make some additions to our Capfile to include bundler, rails, and rbenv. Edit your `Capfile` and add these lines:

```
require 'capistrano/rails'
require 'capistrano/passenger'
require 'capistrano/rbenv'
require "capistrano/bundler"
set :rbenv_type, :user
set :rbenv_ruby, '2.5.1'
```

After we've got Capistrano installed, we can configure the `config/deploy.rb` to setup our general configuration for our app. Edit that file and make it like the following replacing `my_app_name` with the name of your application and git repository:

```
set :application, 'my_app_name'
set :repo_url, 'git@example.com:me/my_repo.git'

set :deploy_to, '/home/deploy/my_app_name'

append :linked_files, 'config/database.yml', 'config/master.key'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads'
```

Now we need to open up our `config/deploy/production.rb` file to set the server IP address that we want to deploy to:

```
# Replace 127.0.0.1 with your server's IP address!
server '127.0.0.1', user: 'deploy', roles: %w{app db web}
```

If you have any trouble with Capistrano or the extensions for it, check out [Capistrano's Github page][capistrano-github].

# Final Steps

Thankfully there aren't a whole lot of things to do left!

## Adding The Nginx Host

In order to get Nginx to respond with the Rails app, we need to modify it's sites-enabled.

Open up `/etc/nginx/sites-enabled/default` in your text editor and we will replace the file's contents with the following:

```
server {
        listen 80;
        listen [::]:80 ipv6only=on;

        server_name mydomain.com;
        passenger_enabled on;
        rails_env    production;
        root         /home/deploy/my_app_name/current/public;

        # redirect server error pages to the static page /50x.html
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
}
```

This is our Nginx configuration for a server listening on port 80. You need to change the `server_name` values to match the domain you want to use and in `root` replace `my_app_name` with the name of your application.

## Connecting The Database

One optional thing I would recommend is to remove your `config/database.yml` and `config/master.key` git and only store example copies in your git repo. This way we can easily copy the files for setting up development, but our production environment can symlink files on the server so that our production secrets and passwords are only stored on the production server.

First we'll move these files to their example names in the git repo.

```
echo "config/database.yml\nconfig/master.key" >> .gitignore
git add .gitignore
git mv config/database.yml config/database.yml.example
git commit -m "Only store example secrets and database configs"
cp config/database.yml.example config/database.yml
```

You can run `cap production deploy` to deploy your application, but it's going to fail this first time because we haven't created either of these files on the server which we will do in just a second.

```
linked file /home/deploy/my_app_name/shared/config/database.yml does not exist on IP_ADDRESS
```

One last time, ssh into your server as the `deploy` user and this time we need to create two files. First is the `database.yml` that uses the password for the postgres user you created earlier.

```
# /home/deploy/my_app_name/shared/config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= Rails.application.credentials[:pghost] %>
  user: <%= Rails.application.credentials[:user] %>
  password: <%= Rails.application.credentials[:pgpass] %>
  timeout: 5000
  database: my_app_name_production
```

To do this, let's skip it on ssh

```
scp config/database.yml deploy@IP_ADDRESS:/home/deploy/my_app_name/shared/config/database.yml
```

Next, we need to copy the `master.key`

```
scp config/master.key deploy@192.168.88.244:/home/deploy/my_app_name/shared/config/master.key
```

You can run `cap production deploy` one last time to get your full deployment to run. This should completed successfully and you should see your new site live! You can just run Capistrano again to deploy any new changes you've pushed up to your Git repository.

## Restarting The Site

One last thing you should know is that restarting just the Rails application with Passenger is very easy. If you ssh into the server, you can run `touch my_app_name/current/tmp/restart.txt` and Passenger will restart the application for you. It monitors the file's timestamp to determine if it should restart the app. This is helpful when you want to restart the app manually without deploying it.

## Conclusion

And there you have it, a very long-winded explanation of all the different things you need to do while setting up an application to be deployed. There is a lot of system administration pieces that can expand upon this, but that's for another time. Please let me know if you have any questions, comments, or suggestions!

[sources.list]: https://gist.github.com/reabiliti/71f949b2bf4817e3a21e78016cf049ca
[capistrano-github]: https://github.com/capistrano
