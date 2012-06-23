use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

#is Maybe->isUndef(undef), 1;
#is Maybe->isUndef(1), 0;
use Data::Dumper;
$Data::Dumper::Maxdepth = 3;

is(Test->getNull, undef);
is(Test->isNull( 1 ), 0);
#is(Test->isNull( undef ), 1);
print Dumper( Test->nestedArray );

done_testing;
    
__END__
__JSX__

class Test {
    static function getNull () : variant {
        return null;
    }

    static function isNull (a:variant) : int {
        return a == null ? 1: 0;
    }

    static function nestedArray () : Array.<Array.<number>> {
        var a = [ [1,2,3], [1,2] ] : Array.<Array.<number>>;
        return a;
    }
}

class Maybe {
    static function isUndef (a:MayBeUndefined.<Array.<number>>) : int {
        return a == undefined ? 1: 0;
    }
}


