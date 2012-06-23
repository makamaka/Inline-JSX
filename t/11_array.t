use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

is( Test->setAV([]), 0);
is( Test->setAV(["a"]), 1);
is( Test->setAV(["a","b"]), 2);
eval { Test->setAV([1]) };
ok( $@ );
eval { Test->setAV([ ["a"] ]) };
ok( $@ );

my $array = Test->createArray();
is_deeply( $array, [1] );

$array = Test->toArray(3);
is_deeply( $array, [3] );

done_testing;
    
__END__
__JSX__

class Test {

    static function setAV (a:Array.<string>) : int {
        return a.length;
    }

    static function createArray () : Array.<number> {
        var v : number[] = [1];
        return v;
    }

    static function toArray (n:number) : Array.<number> {
        return [ n ];
    }

}

