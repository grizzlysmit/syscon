Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

  * [Introduction](#introduction)

    * [Motivations](#motivations)

  * [USAGE](#usage)

    * [sc ssh](#sc-ssh)

    * [USAGE](#usage)

    * [USAGE](#usage)

    * [USAGE](#usage)

    * [USAGE](#usage)

    * [USAGE](#usage)

    * [USAGE](#usage)

NAME
====

syscon 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

v0.1.18

TITLE
=====

syscon

SUBTITLE
========

A module **`Syscon`** and a program **`syscon`** or **`sc`** for short, which keeps tarck of assorted servers and helps to connect to them.

COPYRIGHT
=========

LGPL V3.0+ [LICENSE](https://github.com/grizzlysmit/syscon/blob/main/LICENSE)

Introduction
============

A module **`Syscon`** and a program **`syscon`** or **`sc`** for short, which keeps tarck of assorted servers and helps to connect to them.

[Top of Document](#table-of-contents)

Motivations
-----------

I have to keep track of many servers (> 100) but who can remember all the host names, and ports?? That is where this app comes in I can connect to a server by ssh by.

```bash
$ syscon.raku ssh <key>
```

or for short

```bash
$ sc ssh <key>
```

Equally you can use

```bash
$ sc put home <key> <files> ……
```

To run 

```bash
$ scp -P $port <files> …… $host:
```

  * Where 

    * **`$host`** is generally something like **`username@example.com`**

    * **`$port`** is a port number.

    * **key** is the key to retrieve the host and port form the server.

      * It's put home because I may add put <other-place> at a later date.

[Top of Document](#table-of-contents)

This is the app, you can find the modules docs [here](https://github.com/grizzlysmit/syscon)

### USAGE

```bash
$ sc --help
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/usage.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/usage.png)

[Top of Document](#table-of-contents)

### sc ssh

Runs

```bash
ssh -p $port $host
```

by the **`ssh(…)`**

```raku
multi sub MAIN('ssh', Str:D $key --> int){
    if ssh($key) {
        return 0;
    } else {
        return 1;
    }
}
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-ssh.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-ssh.png)

[Top of Document](#table-of-contents)

