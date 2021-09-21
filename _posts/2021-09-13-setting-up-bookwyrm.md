---
layout: post
title: Setting up Bookwyrm
date: 2021-09-13 15:32 +0200
author: Christoph Kappel
tags: myself tech books bookwyrm social
categories: myself
toc: true
---
As a book enthusiast and long time [GoodReads][5] user, I really liked the idea of [BookWyrm][1],
especially to get rid of some of the shortcomings like poor performance and to be able to limit the
audience just to be my closer circle. (*I know that this isn't the idea of social networking and I
probably lose good suggestions from other users, but still.*)

## How to run it?

Setting up [BookWyrm][1] is quite easy: The default running mode is via [docker-compose][9] which
works perfectly fine on my local machine. When I try the exact same steps on my VM, it also fetches
the different containers (we will come later to that), fires them up until [Postgres][6] fails to
bind to its default port.

## Problems with Postgres

### How to get it running?

I haven't checked in great detail why this happened, maybe the default configuration is to bind
to `0.0.0.0` or something within the network config of [docker-compose][9] is amiss. For my use case
I'd rather be able to use the instance of [Postgres][6] that is already running on my VM, just to
save a bit of resources.

There is no easy way to change the configuration to another database host (or container for that
matter), so I had to force my way through and did the following:

- Commented out everything related to the database in the [docker-compose][9] file.
- Updated the `psql` calls in the `bw-dev` script to run outside of the db container.
- Reconfigured the local [Postgres][6] instance to also bind to the [Docker][4] bridge.

After that, the the database came up perfectly and [docker-compose][9] exited with success.

### Which version exactly?

Next up on the list is to run the database migration to get the initial data in place.
Unfortunately, the `bw-dev` script presented me this goodie:

###### **Log**:
```log
  Applying bookwyrm.0077_auto_20210623_2155...Traceback (most recent call last):
  File "/usr/local/lib/python3.9/site-packages/django/db/backends/utils.py", line 82, in _execute
    return self.cursor.execute(sql)
psycopg2.errors.SyntaxError: syntax error at or near "FUNCTION"
LINE 26:                 FOR EACH ROW EXECUTE FUNCTION book_trigger()...
```

This one is probably on me: Apparently, [BookWyrm][1] uses features from [Postgres][6] **v11**,
which is a problem when you are still running **v9**. [Debian][3] or rather [apt-get][8] is quite
careful, when it installs a new version of your database and you might end up with more than one:

###### **Shell**:
```shell
$ su - postgres -c 'pg_lsclusters' # Ask for existing clusters
Ver Cluster Port Status Owner    Data directory               Log file
9.6 main    5433 online postgres /var/lib/postgresql/9.6/main /var/log/postgresql/postgresql-9.6-main.log
11  main    5432 down   postgres /var/lib/postgresql/11/main  /var/log/postgresql/postgresql-11-main.log
```

Considering the output, it looks like there are two clusters configured and the older one is running,
so we just have to migrate the existing one to **v11**:

###### **Shell**:
```shell
$ su - postgres -c 'pg_dropcluster --stop 11 main' # Delete the empty default cluster
$ su - postgres -c 'pg_upgradecluster 9.6 main'    # Upgrade the other one
```

After _verification_ everything is running properly, I just got rid of **v9.6** entirely:

###### **Shell**`
```shell
$ su - postgres -c 'pg_dropcluster --stop 9.6 main'

$ apt autoremove postgresql-9.6
$ apt autoclean
```

### Why triggers?

The next run of `./bw-dev initdb` went a bit further until it failed with this error:

###### **Shell**:
```log
psycopg2.errors.InsufficientPrivilege: permission denied to create extension "pg_trgm"
```

I am not a big fan of using triggers for business logic, because they make upgrades difficult, kind
of hide logic and don't necessarily convey how something is done. Nevertheless, the easiest way here
was to temporarily elevate the privileges of the database user:

###### **Shell**:
```sql
alter role user_name superuser;
alter role user_name nosuperuser;
```

## Conclusion

Once running, [BookWyrm][1] is quite nice, has a well designed layout and easy to understand UX. I
especially liked, that it includes reading challenges like the ones from [GoodReads][5].

**So the real question is: Am I going to use it?**

I must admit that depends on some things I have to consider:

1. Although I understand the social aspect, I'd really prefer to be able to limit the instances it
can connect to without blocking them directly. (_This is something that doesn't scale well._)
2. Imports from [GoodReads][5] aren't up to par, when I initially imported 96 books which took quite
a while, 23 couldn't be found. This is remarkable, both in the failed in percent and also, if you
consider the export from [GoodReads][5] actually contains the ISBN.
3. The complexity of the stack if kind of frightening, I am not sure the the numbers on the instances
will ever justify the [Celery][2] task queue with [Redis][7] as backend. (_Scaling it when necessary
would have been the better approach, imho._)
4. [docker-compose][9] shouldn't be the default mode. Maybe I will really start to take it apart
and create a documentation how to do that on the way.

You can find my instance of [BookWyrm][1] here:

<https://books.unexist.dev>

[1]: https://bookwyrm.social/
[2]: https://docs.celeryproject.org/en/master/index.html
[3]: https://www.debian.org/
[4]: https://www.docker.com/
[5]: https://www.goodreads.com/
[6]: https://www.postgresql.org/
[7]: https://redis.io/
[8]: https://wiki.debian.org/apt-get
[9]: https://docs.docker.com/compose/