use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

is Maybe->isUndef(undef), 1;
is Maybe->isUndef(1), 0;
is Maybe->isUndef("abc"), 0;
is Maybe->isUndef([1.2]), 0;
is Maybe->isUndef([]), 0;

eval{ Maybe->isUndef(1.5) };
ok( $@ =~ /mismatch/ );

eval{ Maybe->isUndef(["foo"]) };
ok( $@ =~ /mismatch/ );


done_testing;
    
__END__
__JSX__

class Maybe {

    static function isUndef (a:MayBeUndefined.<int>) : int {
        return a == undefined ? 1: 0;
    }

    static function isUndef (a:MayBeUndefined.<string>) : int {
        return a == undefined ? 1: 0;
    }

    static function isUndef (a:MayBeUndefined.<Array.<number>>) : int {
        return a == undefined ? 1: 0;
    }

}


