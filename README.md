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

NAME
====

Syscon 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

v0.1.18

TITLE
=====

Syscon

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

[Top of Document](#able-of-contents)

This is the module.

