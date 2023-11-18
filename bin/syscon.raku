#!/usr/bin/env raku
use v6;
use ECMA262Regex;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;


use Syscon;

#`«««
    ############################################
    #                                          #
    #   The actual work horses of the library  #
    #                                          #
    ############################################
#»»»

multi sub MAIN('ssh', Str:D $key --> int){
    if ssh($key) {
        return 0;
    } else {
        return 1;
    }
}

multi sub MAIN('ping', Str:D $key --> int){
    if ping($key) {
        return 0;
    } else {
        return 1;
    }
}

multi sub MAIN('get', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _get('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}

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

multi sub MAIN('list', 'by', 'both', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-by-both($prefix, $colour, $page-length, $_pattern) {
       exit 0;
    } else {
       exit 1;
    } 
} # multi sub MAIN('list', 'all', Str $prefix = '', Bool:D :c(:color(:$colour)) = False, Str :p(:$pattern) = Str, Str :e(:$ecma-pattern) = Str) returns Int #

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

multi sub MAIN('list', 'trash', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if list-commented($colour, $syntax) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('stats', Bool:D :c(:color(:$colour)) = False) returns Int {
   if stats($colour) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('statistics', Bool:D :c(:color(:$colour)) = False) returns Int {
   if stats($colour) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('delete', Bool:D :o(:$comment-out) = False, *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, True) {
            $result++;
        } 
    }
    exit $result;
}

multi sub MAIN('del', Bool:D :o(:$comment-out) = False, *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, True) {
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

multi sub MAIN('help', Bool:D :n(:nocolor(:$nocolour)) = False) returns Int {
   if $nocolour {
       $*USAGE.say;
   } else {
       say-coloured($*USAGE);
   } 
   exit 0;
}

sub USAGE() {
    say-coloured($*USAGE);
}
