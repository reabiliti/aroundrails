---
layout: post
title: "Production Server Database And File Backups"
date: "2019-04-14 05:48:47 +0300"
last_modified_at: "2019-04-14 05:48:47 +0300"
categories: rails
---

# Overview

It's incredibly dangerous to run a production server without setting up automatic backups.
I often go with hourly database and file backups on my production servers.
If anything goes wrong, we've got a recent backup to restore from. 

This is pretty simple to setup with the [Backup gem][backup-gem]{:target="_blank"} and has all the features we could need
including email alerts when things go wrong.

# Install the Backup gem

Login into your server with the same user account that your app runs as. For me, this is the `deploy` user.

Assuming you've already setup your server, you should already have Ruby installed.
You can simply install the latest version of the backup gem like so:

```
gem install backup -v 5.0.0.beta.2
```

# Setup your Backup script

First we want to generate a new backup script:

```
backup generate:model --trigger production_backup
```

This will generate a folder in your user's home directory called `Backup` It will have a couple files inside:


* **config.rb -** This is your main Backup configuration file. You can read through this if you like, but you probably won't need to change it
* **log -** This is the where the backup logs are stored
* **models -** This folder contains your scripts, specifically `production_backup.rb` that we just generated

Now we can edit `~/Backup/models/production_backup.rb` to backup our database, files, and notify us.

Open this file with Vim or Nano. I'll be using Vim:

```
vim ~/Backup/models/production_backup.rb
```

Replace the contents with the following config:

```
# encoding: utf-8

##
# Backup Generated: production_backup
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t production_backup [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://backup.github.io/backup
#
Model.new(:production_backup, 'Description for production_backup') do
  split_into_chunks_of 250
  compress_with Gzip

  database PostgreSQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = 'my_database_name'
    db.username           = 'my_username'
    db.password           = 'my_password'
    db.host               = 'localhost'
    db.port               = 5432
    # db.socket             = '/tmp/pg.sock'
    # When dumping all databases, `skip_tables` and `only_tables` are ignored.
    # db.skip_tables        = []
    # db.only_tables        = []
    db.additional_options = ['-xc', '-E=utf8']
  end

  time = Time.now
  if time.day == 1
    storage_id = :monthly
    keep = 12
  elsif time.sunday?
    storage_id = :weekly
    keep = 4
  else
    storage_id = :daily
    keep = 7
  end

  store_with S3, storage_id do |s3|
    # AWS Credentials
    s3.access_key_id     = 'my_access_key_id'
    s3.secret_access_key = 'my_secret_access_key'
    # Or, to use a IAM Profile:
    # s3.use_iam_profile = true

    s3.region             = 'us-east-2'
    s3.bucket             = 'bucket-name'
    s3.path               = "backups/#{storage_id.to_s}/"
    s3.keep               = keep
  end

  store_with Local, storage_id do |local|
    local.path       = "~/backups/#{storage_id.to_s}/"
    local.keep       = keep
  end

  notify_by Slack do |slack|
    slack.on_success = true
    slack.on_warning = true
    slack.on_failure = true

    # The integration token
    slack.webhook_url = 'my_webhook_url'

    ##
    # Optional
    #
    # The channel to which messages will be sent
    # slack.channel = 'my_channel'
    #
    # The username to display along with the notification
    # slack.username = 'Backup Bot'
    #
    # The emoji icon to use for notifications.
    # See http://www.emoji-cheat-sheet.com for a list of icons.
    # slack.icon_emoji = ':ghost:'
    #
    # Change default notifier message.
    # See https://github.com/backup/backup/pull/698 for more information.
    # slack.message = lambda do |model, data|
    #   "[#{data[:status][:message]}] #{model.label} (#{model.trigger})"
    # end
  end
end
```

# Test your Backup script

This is easy. Just run the following in your terminal. It will automatically detect the script in the models folder and run it for you.

```
backup perform -t production_backup
```

You should get some output telling you what the Backup is doing and, if you configured everything correctly,
it will succeed and you will have a new file stored in your S3 bucket.

# Schedule Your Backups

Now we need to make this script run every day. We're going to use Cron to do this.

So first, let's grab the executable path:

```
which backup
# /home/deploy/.rbenv/shims/backup
```

Take note of the output of this command because you're going to use it next.

And now let's type `crontab -e` to setup our Cron job. Add a line at the bottom that looks like the following:

```
30 4 * * * /bin/bash -l -c '/home/deploy/.rbenv/shims/backup perform -t production_backup'
```

Be sure to replace `/home/deploy/.rbenv/shims/backup` with the output of the `which backup` command.
This will make sure the Cron job can find the executable for Backup so that it can run your script.

This line basically tells Cron to perform the backup at the top of every hour. The cron format can be kind of hard to read,
so if you'd like to learn more about it, take a look [here][wiki-cron]{:target="_blank"}.

If editing the crontab by hand doesn't strike your fancy, you can also use
the [Whenever gem to manage your backup Cron job][scheduling-backups]{:target="_blank"} instead.
This does let you save your cron jobs into your Git repo so you can manage them easily. Definitely worth checking out.

# Recovery PostgreSQL database

```
tar -xf production_backup.tar
cd production_backup/databases
gzip -d PostgreSQL.sql.gz
psql -U my_username -h localhost -d my_database_name -f PostgreSQL.sql
```

# Conclusion

With the Backup gem, it's super simple to backup your application and production data. Since your code is stored
in a Git repository (I hope!) you don't need to worry about it too much. But when it comes to production data,
you want to make sure it is backed up regularly, on a schedule, and saved to a remote machine in case anything
happens to the server. The Backup gem helps you through a whole lot of this process with relative ease and a great
amount of documentation.

[backup-gem]: http://backup.github.io/backup/v4/
[wiki-cron]: https://en.wikipedia.org/wiki/Cron
[scheduling-backups]: http://backup.github.io/backup/v4/scheduling-backups/
