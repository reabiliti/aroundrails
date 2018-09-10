---
layout: post
title:  "Running Sidekiq as a service on Ubuntu"
date:   2018-09-01 02:25:17 +0300
categories: article
---

# Introduction

[Sidekiq][sidekiq-github] uses [Redis][redis-site] to store all of its job and operational data.

By default, Sidekiq tries to connect to Redis at `localhost:6379`. This typically works great during development but needs tuning in production.

# Installing Redis-server

The installation is as simple as:

```
$ sudo apt install redis
```

Once the Redis server installation is finished you can check the Redis server version:

```
$ redis-server -v
Redis server v=4.0.8 sha=00000000:0 malloc=jemalloc-3.6.0 bits=64 build=2d97cb0719f78c3e
```

Furthermore, confirm that Redis server is up and running as expected by checking for its listening socket on port number `6379`:

```
$ ss -nlt
State       Recv-Q Send-Q Local Address:Port               Peer Address:Port
LISTEN      0      128       0.0.0.0:22                    0.0.0.0:*
LISTEN      0      128     127.0.0.1:6379                  0.0.0.0:*
LISTEN      0      128          [::]:22                       [::]:*
LISTEN      0      128         [::1]:6379                     [::]:*
```

The Redis server will start after reboot. To manipulate this default behavior you can either disable or enable the Redis start after reboot by:

```
$ sudo systemctl disable redis-server
OR
$ sudo systemctl enable redis-server
```

By default the Redis server will listen only on a local loop-back interface `127.0.0.1`.

If you need to configure your Redis server to listen on all networks you will need to configure its main configuration file `/etc/redis/redis.conf`:

```
$ sudo vim /etc/redis/redis.conf
```

and comment the bind 127.0.0.1 ::1:

```
FROM:
bind 127.0.0.1 ::1
TO:
# bind 127.0.0.1 ::1
```

Furthermore, if you wish to connect to your Redis server remotely you need to turn off redis protected mode. While still editing `/etc/redis/redis.conf` find `protected-mode yes` line and change it:

```
FROM:
protected-mode yes
TO:
protected-mode no
```

Once the configuration is completed restart Redis server:

```
$ sudo systemctl restart redis-server
```

The Redis server should be now listening on socket `0.0.0.0:6379`. You can confirm this by executing the ss command:

```
$ ss -nlt
State       Recv-Q Send-Q Local Address:Port               Peer Address:Port
LISTEN      0      128       0.0.0.0:22                    0.0.0.0:*
LISTEN      0      128       0.0.0.0:6379                  0.0.0.0:*
LISTEN      0      128          [::]:22                       [::]:*
LISTEN      0      128          [::]:6379                     [::]:*
```

Lastly, if you have the UFW firewall enabled you can open the Redis's port `6379` to any TCP incoming traffic by executing the below command:

```
$ sudo ufw allow from any to any port 6379 proto tcp
Rule added
Rule added (v6)
```

# Integration Sidekiq with systemd

Add `capistrano-sidekiq` to your `Gemfile`

```
gem 'capistrano-sidekiq' , group: :development
```

Load the following in your `Capfile`

```
require 'capistrano/sidekiq'
```

Load the following in your `config/deploy.rb`

```
# Sidekiq
set :bundler_path, "/home/deploy/.rbenv/bin/rbenv exec bundle"
set :init_system, :systemd
set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }
```

Create configuration file `config/sidekiq.yml`

```
:concurrency: 1
:pidfile: tmp/pids/sidekiq.pid
:logfile: log/sidekiq.log
staging:
  :concurrency: 2
production:
  :concurrency: 10
:queues:
  - default
  - mailers
```

`capistrano-sidekiq` adds some default hooks:

```
task :add_default_hooks do
  after 'deploy:starting', 'sidekiq:quiet'
  after 'deploy:updated', 'sidekiq:stop'
  after 'deploy:reverted', 'sidekiq:stop'
  after 'deploy:published', 'sidekiq:start'
end
```

Run `cap -T sidekiq` in the terminal to get a full list of the sidekiq commands:

```
cap sidekiq:quiet                  # Quiet sidekiq (stop processing new tasks)
cap sidekiq:respawn                # Respawn missing sidekiq proccesses
cap sidekiq:restart                # Restart sidekiq
cap sidekiq:rolling_restart        # Rolling-restart sidekiq
cap sidekiq:start                  # Start sidekiq
cap sidekiq:stop                   # Stop sidekiq
```

Install systemd.service template file and enable the service with:

```
cap stage sidekiq:install
```

Default name for the service file is `sidekiq-stage.service`. This can be changed as needed, for example:

```
set :service_unit_name, "sidekiq-#{fetch(:application)}-#{fetch(:stage)}.service"
```

[sidekiq-github]: https://github.com/mperham/sidekiq
[redis-site]: https://redis.io/
