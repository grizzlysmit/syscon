#!/usr/bin/env raku
use v6;
use ECMA262Regex;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;

=begin pod

=begin head2

Table of  Contents

=end head2

=item1 L<NAME|#name>
=item1 L<AUTHOR|#author>
=item1 L<VERSION|#version>
=item1 L<TITLE|#title>
=item1 L<SUBTITLE|#subtitle>
=item1 L<COPYRIGHT|#copyright>
=item1 L<Introduction|#introduction>
=item2 L<Motivations|#motivations>
=item1 L<USAGE|#usage>
=item2 L<The actual work horses of the library|#the-actual-work-horses-of-the-library>
=item3 L<sc ssh|#sc-ssh>
=item3 L<sc ping|#sc-ping>
=item3 L<sc get home|#sc-get-home>
=item3 L<sc put home|#sc-put-home>
=item2 L<Utility functions|#utility-functions>
=item3 L<sc edit configs|#sc-edit-configs>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>

=NAME syscon 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION v0.1.18
=TITLE syscon
=SUBTITLE A module B<C<Syscon>> and a program B<C<syscon>> or B<C<sc>> for short, which keeps tarck of assorted servers and helps to connect to them.

=COPYRIGHT
LGPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/syscon/blob/main/LICENSE>

=head1 Introduction

A module B<C<Syscon>> and a program B<C<syscon>> or B<C<sc>> for short, which keeps tarck of assorted
servers and helps to connect to them.

L<Top of Document|#table-of-contents>

=head2 Motivations

I have to keep track of many servers (> 100) but who can remember all the host names, and ports??
That is where this app comes in I can connect to a server by ssh by.

=begin code :lang<bash>

$ syscon.raku ssh <key>

=end code

or for short

=begin code :lang<bash>

$ sc ssh <key>

=end code

Equally you can use

=begin code :lang<bash>

$ sc put home <key> <files> ……

=end code

To run 

=begin code :lang<bash>

$ scp -P $port <files> …… $host:

=end code

=item1 Where 
=item2 B<C<$host>> is generally something like B<C<username@example.com>>
=item2 B<C<$port>> is a port number.
=item2 B<key> is the key to retrieve the host and port form the server.
=item3 It's put home because I may add put <other-place> at a later date.

L<Top of Document|#table-of-contents>

This is the app, you can find the modules docs L<here|https://github.com/grizzlysmit/syscon>

=end pod


use Gzz::Text::Utils;
#use Syntax::Highlighters;
use GUI::Editors;
use Usage::Utils;
use Syscon;

=begin pod

=head3 USAGE

=begin code :lang<bash>

$ sc --help

=end code

!L<https://github.com/grizzlysmit/syscon/blob/main/docs/images/usage.png>

L<Top of Document|#table-of-contents>

=end pod

#`«««
    ############################################
    #                                          #
    #   The actual work horses of the library  #
    #                                          #
    ############################################
#»»»

=begin pod

=head2 The actual work horses of the library

=head3 sc ssh

Runs

=begin code :lang<bash>

ssh -p $port $host

=end code

by the B<C<ssh(…)>> function defined in B<Syscon.rakumod>.

=begin code :lang<raku>

multi sub MAIN('ssh', Str:D $key --> int){
    if ssh($key) {
        return 0;
    } else {
        return 1;
    }
}

=end code


!L<https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-ssh.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('ssh', Str:D $key --> int){
    if ssh($key) {
        return 0;
    } else {
        return 1;
    }
}

=begin pod

=head3 sc ping

Runs

=begin code :lang<bash>

$ sc ping $server

=end code

=item1 Where
=item2 B<C<$server>> is the domain part of the host value i.e. with the B<C<username@>> removed.

!L<https://github.com/grizzlysmit/syscon/blob/main/docs/images/ping.png>

by the B<C<sc ping $key>>

=begin code :lang<raku>

multi sub MAIN('ping', Str:D $key --> int){
    if ping($key) {
        return 0;
    } else {
        return 1;
    }
}

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('ping', Str:D $key --> int){
    if ping($key) {
        return 0;
    } else {
        return 1;
    }
}

=begin pod

=head3 sc get home

Get some files on the remote system and deposit them here (in the directory the user is currently in).

=begin code :lang<bash>

$ sc get home $key $files-on-remote-system……

=end code

!L<https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-get-home.png>

Defined as 

=begin code :lang<raku>

multi sub MAIN('get', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _get('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}

=end code

Using the B<C<_get(…)>> function defined in B<Syscon.rakumod>.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('get', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _get('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}

=begin pod

=head3 sc put home

=begin code :lang<bash>

$ sc put home $key $files……

=end code

=item1 Where
=item2 B<C<$key>> is as always the key to identify the host in question.
=item2 B<C<$files>>…… is a list of files to copy to the remote server.

!L<https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-put-home.png>

Implemented as

=begin code :lang<raku>

multi sub MAIN('put', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _put('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}

=end code

=item1 Where
=begin item2 

B<C<multi sub _put('home', Str:D $key, Bool :r(:$recursive) = False, *@args --> Bool) is export>>
is a function in B<Sysycon.rakumod>

=end item2

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('put', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _put('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}

#`«««
    ##################################
    #********************************#
    #*                              *#
    #*      Utility functions       *#
    #*                              *#
    #********************************#
    ##################################
#»»»

=begin pod

=head2 Utility functions

=head3 sc edit configs

=begin code :lang<bash>

$ sc edit configs

=end code

Implemented by the B<C<edit-configs>> function in the B<GUI::Editors.rakumod> module.
This open your configuration files in your preferred GUI editor, if you have one, if 
you don't have one of those setup it will try for a good substitute, failing
that it will Fail and print an error message. 

Do not use this it's for experts only, instead use the B<set-*(…)> functions below.

=begin code :lang<raku>

multi sub MAIN('edit', 'configs') returns Int {
   if edit-configs() {
       exit 0;
   } else {
       exit 1;
   } 
}

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('edit', 'configs') returns Int {
   if edit-configs() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('list', 'keys', Str $prefix = '', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if say-list-keys($prefix, $colour, $syntax, $_pattern, $page-length) {
       exit 0;
    } else {
       exit 1;
    } 
}

multi sub MAIN('list', 'all', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-all($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
    } else {
       exit 1;
    } 
} # multi sub MAIN('list', 'all', Str $prefix = '', Bool:D :c(:color(:$colour)) = False, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int #

multi sub MAIN('list', 'hosts', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-hosts($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
    } else {
       exit 1;
    } 
} # multi sub MAIN('list', 'all', Str $prefix = '', Bool:D :c(:color(:$colour)) = False, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int #

multi sub MAIN('list', 'by', 'both', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-by-both($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
    } else {
       exit 1;
    } 
} # multi sub MAIN('list', 'all', Str $prefix = '', Bool:D :c(:color(:$colour)) = False, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int #

multi sub MAIN('list', 'by', 'all', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False,
                    Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str,
                                                                Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-by-all($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
    } else {
       exit 1;
    } 
} #`««« multi sub MAIN('list', 'by', 'all', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False,
                    Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str,
                                                                Str :e(:$ecma-pattern) = Str) returns Int »»»

multi sub MAIN('list', 'commented', 'out', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if list-commented($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('list', 'trash', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if list-commented($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('stats', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if stats($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
} # multi sub MAIN('stats', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int #

multi sub MAIN('statistics', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if stats($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
} # multi sub MAIN('statistics', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int #

multi sub MAIN('add', Str:D $key, Str:D $host, PortVal:D $port = 22, Bool:D :s(:set(:$force)) = False, Str :c(:$comment) = Str) returns Int {
   if add-host($key, $host, $port, $force, $comment) {
       exit 0;
   } else {
       exit 1;
   }
}

multi sub MAIN('delete', Bool:D :o(:$comment-out) = False, *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, $comment-out) {
            $result++;
        } 
    }
    exit $result;
}

multi sub MAIN('del', Bool:D :o(:$comment-out) = False, *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, $comment-out) {
            $result++;
        } 
    }
    exit $result;
}

multi sub MAIN('trash', *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, True) {
            $result++;
        } 
    }
    exit $result;
}

multi sub MAIN('empty', 'trash') returns Int {
   if empty-trash() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('undelete', *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless undelete($key) {
            $result++;
        } 
    }
    exit $result;
}

multi sub MAIN('comment', Str:D $key, Str:D $comment) returns Int {
    if add-comment($key, $comment) {
        exit 0;
    } else {
        exit 1;
    } 
}

multi sub MAIN('alias', Str:D $key, Str:D $target, Bool:D :s(:set(:$force)) = False, Bool:D :d(:really-force(:$overwrite-hosts)) = False, Str :c(:$comment) = Str) returns Int {
   if add-alias($key, $target, $force, $overwrite-hosts, $comment) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('backup', 'db', Bool:D :w(:win-format(:$use-windows-formating)) = False --> Bool) {
    if backup-db-file($use-windows-formating) {
        exit 0;
    } else {
        die "Error: backup failed!!!";
    }
}

multi sub MAIN('restore', 'db', Str $restore-from = Str --> Bool) {
    my IO::Path $_restore-from;
    with $restore-from {
        $_restore-from = $restore-from.IO;
    }
    if restore-db-file($_restore-from) {
        exit 0;
    } else {
        die "Error: restore backup failed!!!";
    }
}

#`«««
    ##################################
    #********************************#
    #*                              *#
    #*       Editor functions       *#
    #*                              *#
    #********************************#
    ##################################
#»»»

multi sub MAIN('list', 'editors', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if list-editors($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('list', 'editors', 'file', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if list-editors-file($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('editors', 'stats', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if editors-stats($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('list', 'editors', 'backups', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if list-editors-backups($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('backup', 'editors', Bool:D :w(:$use-windows-formatting) = False) returns Int {
   if backup-editors($use-windows-formatting) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('restore', 'editors', Str:D $restore-from) returns Int {
   if restore-editors($restore-from.IO) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('set', 'editor', Str:D $editor, Str $comment = Str) returns Int {
   if set-editor($editor, $comment) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('set', 'override', 'GUI_EDITOR', Bool:D $value, Str $comment = Str) returns Int {
   if set-override-GUI_EDITOR($value, $comment) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('menu', 'restore', 'editors', Str:D $message = '', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if backups-menu-restore($colour, $syntax, $message) {
       exit 0;
   } else {
       exit 1;
   } 
}

#`«««
    #########################################################
    #                                                       #
    #   vanity functions no real point in their existance   #
    #                                                       #
    #########################################################
#»»»

multi sub MAIN('tidy', 'file') returns Int {
   if tidy-file() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('sort', 'file') returns Int {
   if sort-file() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('show', 'file', Bool:D :c(:color(:$colour)) = False) returns Int {
   if show-file($colour) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('help', Bool:D :n(:nocolor(:$nocolour)) = False, *%named-args, *@args) returns Int {
   my @_args is Array[Str] = |@args[1 .. *];
   #say @_args.shift;
   say-coloured($*USAGE, $nocolour, |%named-args, |@_args);
   exit 0;
}

multi sub MAIN('test') returns Int {
   test();
   exit 0;
}

#`«««
    ***********************************************************
    *                                                         *
    *                       USAGE Stuff                       *
    *                                                         *
    ***********************************************************
#»»»

sub USAGE(Bool:D :n(:nocolor(:$nocolour)) = False, *%named-args, *@args --> Int) {
    say-coloured($*USAGE, False, %named-args, @args);
    exit 0;
}

multi sub GENERATE-USAGE(&main, |capture --> Int) {
    my @capture = |(capture.list);
    my @_capture;
    if @capture && @capture[0] eq 'help' {
        @_capture = |@capture[1 .. *];
    } else {
        @_capture = |@capture;
    }
    my %capture = |(capture.hash);
    if %capture«nocolour» || %capture«nocolor» || %capture«n» {
        say-coloured($*USAGE, True, |%capture, |@_capture);
    } else {
        #dd @capture;
        say-coloured($*USAGE, False, |%capture, |@_capture);
        #&*GENERATE-USAGE(&main, |capture)
    }
    exit 0;
}
