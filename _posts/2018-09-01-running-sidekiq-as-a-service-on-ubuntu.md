---
layout: post
title:  "Running Sidekiq as a service on Ubuntu"
date:   2018-09-01 02:25:17 +0300
categories: Ruby Rails Ubuntu Sidekiq Redis
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

# Add Sidekiq as service

Sidekiq auto start using systemd unit file for Ubuntu 18.04.

Put this in `/lib/systemd/system/sidekiq.service` by executing the below command:

```
$ sudo vim /lib/systemd/system/sidekiq.service
```

And add the following settings taken from the [file][sidekiq-service-gist]:

```
[Unit]
Description=sidekiq
# start us only once the network and logging subsystems are available,
# consider adding redis-server.service if Redis is local and systemd-managed.
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/home/Public/Rails/your-rails-app
ExecStart=/home/deploy/.rbenv/bin/rbenv exec bundle exec sidekiq -e production -c 3 -q mailers -q default
User=deploy
Group=deploy
UMask=0002

# if we crash, restart
RestartSec=1
Restart=on-failure

# output goes to /var/log/syslog
StandardOutput=syslog
StandardError=syslog

# This will default to "bundler" if we don't specify it
SyslogIdentifier=sidekiq

[Install]
WantedBy=multi-user.target
```

Then turn on the service with the following commands:

```
$ systemctl enable sidekiq # to enable sidekiq service
$ systemctl {start,stop,restart} sidekiq # to start sidekiq service
```

This file corresponds to a single Sidekiq process. Add multiple copies to run multiple processes (sidekiq-1, sidekiq-2, etc).

See [Inspeqtor's Systemd][inspeqtor-systemd-wiki] wiki page for more detail about Systemd:

[sidekiq-github]: https://github.com/mperham/sidekiq
[redis-site]: https://redis.io/
[sidekiq-service-gist]: https://gist.github.com/reabiliti/7204115b433e7bd986343d7709f05c2a
[inspeqtor-systemd-wiki]: https://github.com/mperham/inspeqtor/wiki/Systemd
