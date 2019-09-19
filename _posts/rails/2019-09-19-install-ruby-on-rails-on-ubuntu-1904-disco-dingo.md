---
layout: post
title: "Install Ruby On Rails on Ubuntu 19.04 Disco Dingo"
date: "2019-09-19 17:05:34 +0300"
last_modified_at: "2019-09-19 17:05:34 +0300"
categories: rails
---

# Introduction

This will take about 30 minutes.

We will be setting up a Ruby on Rails development environment on Ubuntu 19.04 Disco Dingo.

The reason we're going to be using Ubuntu is because the majority of code you write will run on a Linux server.
Ubuntu is one of the easiest Linux distributions to use with lots of documentation so it's a great one to start with.

You'll want to download the latest Desktop version here:
[http://releases.ubuntu.com/19.04/][download-ubuntu-19-04]{:target="_blank"}.

Some of you may choose to develop on Ubuntu Server so that your development environment matches your production server.
You can find it on the same download link above.

# Preparation

The first step is to install some dependencies for Ruby and Rails.

To make sure we have everything necessary for Webpacker support in Rails, we're first going to start by adding
the Node.js and Yarn repositories to our system before installing them.

```bash
sudo apt-get update
sudo apt upgrade
sudo apt-get install curl
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get update
sudo apt-get install git-core vim zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn
```

# Install Z-shell (Oh My Zsh)

For convenience, it's cool to use `Oh My Zsh`

Install prerequisite packages (ZSH, powerline & powerline fonts).

```bash
sudo apt install zsh
sudo apt-get install powerline fonts-powerline
```

Clone the Oh My Zsh Repo

```bash
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
```

Create a New ZSH configuration file

```bash
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```

Change your Default Shell

```bash
chsh -s $(which zsh)
```

Reboot system.

# Installing Ruby

Next we're going to be installing Ruby using `rbenv`.

```bash
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.zshrc
exec $SHELL

rbenv install 2.6.4
rbenv global 2.6.4
ruby -v
```

The last step is to install Bundler

```bash
gem install bundler
```

rbenv users need to run `rbenv rehash` after installing bundler.

# Configuring Git

We'll be using Git for our version control system so we're going to set it up to match our Github account.

Replace my name and email address in the following steps with the ones you used for your Github account.

```bash
git config --global color.ui true
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR@EMAIL.com"
ssh-keygen -t rsa -b 4096 -C "YOUR@EMAIL.com"
```

The next step is to take the newly generated SSH key and add it to your Github account. You want to copy and paste
the output of the following command and [paste it here][github-settings]{:target="_blank"}.

```bash
cat ~/.ssh/id_rsa.pub
```

Once you've done this, you can check and see if it worked:

```bash
ssh -T git@github.com
```

You should get a message like this:

```bash
Hi excid3! You've successfully authenticated, but GitHub does not provide shell access.
```

# Installing Rails

```bash
gem install rails -v 6.0.0
```

You'll need to run the following command to make the rails executable available:

```bash
rbenv rehash
```

Now that you've installed Rails, you can run the `rails -v` command to make sure you have everything installed
correctly:

```bash
rails -v
# Rails 6.0.0
```

If you get a different result for some reason, it means your environment may not be setup properly.

# Setting Up PostgreSQL

For PostgreSQL, we're going to add a new repository to easily install a recent version of Postgres.

```bash
sudo apt install postgresql-11 libpq-dev
```

The postgres installation doesn't setup a user for you, so you'll need to follow these steps to create a user with
permission to create databases. Feel free to replace `reabiliti` with your username.

```bash
sudo -u postgres createuser reabiliti -s

# If you would like to set a password for the user, you can do the following
sudo -u postgres psql
postgres=# \password reabiliti
```

Now that you've got your machine setup, it's time to start building some Rails applications.

[download-ubuntu-19-04]: http://releases.ubuntu.com/19.04/
[github-settings]: https://github.com/settings/ssh
