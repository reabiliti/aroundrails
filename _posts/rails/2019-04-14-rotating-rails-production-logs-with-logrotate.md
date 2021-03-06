---
layout: post
title: "Rotating Rails Production Logs with LogRotate"
date: "2019-04-14 02:22:05 +0300"
last_modified_at: "2019-04-14 02:22:05 +0300"
categories: rails
---

# Configuring Logrotate For Rails Production Logs

You might be surprised at just how easy to setup logrotate Rails logs is. The reason it is so handy is that a bunch of
your operating system software is already using it. We just have to plug in our configuration and we’re set!

The first step is to open up `/etc/logrotate.conf` using `vim` or `nano`. Jump to the bottom of the file an add the following
block of code. You’ll want to change the first line to match the location where your Rails app is deployed. Mine is under
the `deploy` user’s home directory. Make sure to point to the log directory with the `*.log` bit on the end so that we rotate all the log files.

```
/home/deploy/APPNAME/current/log/*.log {
  daily
  missingok
  rotate 7
  compress
  delaycompress
  notifempty
  copytruncate
}
```

# How It Works

This is fantastically easy. Each bit of the configuration does the following:

* **daily –** Rotate the log files each day. You can also use weekly or monthly here instead.
* **missingok –** If the log file doesn’t exist, ignore it
* **rotate 7 –** Only keep 7 days of logs around
* **compress –** GZip the log file on rotation
* **delaycompress –** Rotate the file one day, then compress it the next day so we can be sure that it won’t interfere with the Rails server
* **notifempty –** Don’t rotate the file if the logs are empty
* **copytruncate –** Copy the log file and then empties it. This makes sure that the log file Rails is writing to always exists so you won’t
get problems because the file does not actually change. If you don’t use this, you would need to restart your Rails application each time.

# Running Logrotate

Since we just wrote this configuration, you’ll want to test it.

To run logrotate manually, we just do: `sudo /usr/sbin/logrotate -f /etc/logrotate.conf`

You’re going to want to run it a second time to make sure the `delaycompress` option is working and to actually compress the log.
Here’s an example of what you’ll see if you `ls` the log folder after running `logrotate` twice:

![Production logs]({{ "/assets/images/screen_production_logs.png" | absolute_url }})

You can see that the `production.log` still exists, `production.log.1` is a copy of the logs between the first and second run of logrotate,
and `production.log.2.gz` is the 300MB behemoth of a log file that we had before compressed nicely with Gzip. Once we get up to 7 log files,
the next time logrotate runs, it will delete the oldest one so that we only have 7 days worth of logs. If you want to keep all the logs around,
you can remove the rotate line from the configuration.

Plus, since we just edited the main logrotate.conf file, the cron job will automatically execute the logrotate Rails logs daily!

# Setting Up LogRotate Rails Logs Isn’t So Bad After All!

Congratulations, you’re set! I’ve had a few cases where the filesystem filled up on a server before and believe me, that is no fun.
This [stackoverflow post][stackoverflow-post]{:target="_blank"} also has a nice configuration for a weekly rotate that keeps a year’s worth of logs that you might find helpful.

[stackoverflow-post]: http://stackoverflow.com/questions/4883891/ruby-on-rails-production-log-rotation
