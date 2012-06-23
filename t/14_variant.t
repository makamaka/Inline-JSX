use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

is( Test->setAnything(undef), 1);
is( Test->setAnything(1), 1);
is( Test->setAnything(1.2), 1);
is( Test->setAnything("a"), 1);
is( Test->setAnything([]), 1);
is( Test->setAnything(["a"]), 1);
is( Test->setAnything({}), 1);
is( Test->setAnything({"foo"=>"bar"}), 1);
is( Test->setAnything( Test->new ), 1);

is_deeply( Test->createAnything(4), {"foo"=>"bar"}, 'map' );
is_deeply( Test->createAnything(3), [1], 'array' );
is( Test->createAnything(2), "string", 'string' );
is( Test->createAnything(1), 1.5, 'number' );

is( Test->echo(undef), undef );
is( Test->echo(1), 1 );
is( Test->echo(1.5), 1.5 );
is_deeply( Test->echo([1,2]), [1,2] );
is_deeply( Test->echo({"foo"=>"bar"}), {"foo"=>"bar"} );
is_deeply( Test->echo([[1,2]]), [[1,2]] );
is_deeply( Test->echo({"foo"=>[1,2]}), {"foo"=>[1,2]} );

is( Test->add("1", 23), 123 );
is( Test->add(1, 23), 24 );

done_testing;
    
__END__
__JSX__

class Test {

    static function setAnything (a:variant) : int {
        return 1;
    }

    static function echo (a:variant) : variant {
        return a;
    }

    static function add (a:int, b:variant) : int {
        return a + b as int;
    }

    static function add (a:string, b:variant) : string {
        return a + b as string;
    }

    static function createAnything (a:int) : variant {
        if ( a == 1 ) {
            return 1.5;
        }
        else if ( a == 2 ) {
            return "string";
        }
        else if ( a == 3 ) {
            return [1];
        }
        else {
            return {"foo":"bar"};
        }
    }

}


