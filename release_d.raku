#!/usr/bin/env raku
use JSON::Fast;

sub MAIN() {
    given from-json(slurp('META6.json')) -> (:$version!, *%) {
        my Str:D $datetime = DateTime.now.Str;
        my Str:D $filename = "archive/{$datetime}-Gzz-Text-Utils-{$version}.tar.gz";
        my Str:D $archive  = "git archive --format=tar.gz --output=$filename HEAD";
        $archive.say;
        shell($archive);
        #shell("git add $filename");
        my Str:D $fez = "fez upload --file=$filename";
        $fez.say;
        shell($fez);
        tag("release-$version");
    }
}

sub tag($tag) {
    shell "git tag -a -m '$tag' $tag && git push --tags origin"
}
