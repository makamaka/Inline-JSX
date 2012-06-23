use strict;
use Test::More;
use t::Utils;

my $fh;
my $out = '';
BEGIN { open($fh, '>>', \$out) or die $!; }

use Inline JSX => 'DATA', CONSOLE_STDOUT => $fh, DIRECTORY => '_Inline_test';

_Main->main([]);

my @tests = split/\n/, $out, 10;

is( @tests, 10 );
is $tests[0], '{}';
is $tests[1], q/{ foo: 'bar', hoge: 'fuga' }/;
is $tests[2], q/[ 1, 2, 3 ]/;
is $tests[3], q/[ '1', '2', '3' ]/;
is $tests[4], '[]';
is $tests[5], q/1 2 '3' 'foo'/;
is $tests[6], 'true false null undefined';
is $tests[7], '{ x: 0, y: 0, a: 0 }';
is $tests[8], '{ foo: [ 1, 2 ] }';

like $tests[9], qr/function .+\(i\) \{/;

done_testing;
    
__END__
__JSX__

class Point {
    var x = 0;
    var y = 0;
    var a = 0;
}

class _Main {
    static function main (args:string[]) : void {
        var map = {} : Map.<string>;
        log map;
        log {"foo":"bar", "hoge":"fuga"};
        log [1,2,3];
        log ['1','2','3'];
        log args;
        log 1, 2, '3', "foo";
        log true, false, null, undefined;
        log new Point ();
        log {foo:[1,2]};
        log function (i:int) : int { return 2 * i; };
    }
}


