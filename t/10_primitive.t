use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

use Data::Dumper;

is( Test->getInt(), 1 );
is( Test->getNumber(), 1.5 );
is( Test->getString(), "foo" );
is( Test->getTrue(), 1 );
is( Test->getFalse(), !1 );

done_testing;
    
__END__
__JSX__

class Test {

    static function getInt () : int {
        return 1;
    }

    static function getNumber () : number {
        return 1.5;
    }

    static function getString () : string {
        return "foo";
    }

    static function getTrue () : boolean {
        return true;
    }

    static function getFalse () : boolean {
        return false;
    }

}



