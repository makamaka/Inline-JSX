use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

is Addition->add(1, 2), 3, 'add number';
is Addition->add('foo', 'bar'), 'foobar',  'add string';
eval { Addition->add('foo', 2) };
ok( $@ =~ /mismatch/, 'type mismatch' );
eval { Addition->add(1, 2, 3) };
ok( $@ =~ /mismatch/, 'type mismatch' );

done_testing;
    
__END__
__JSX__

    class _Main {
        static function main(s:string[]) : void {
            log Addition.add(1, 2);
        }
    }

    class Addition {
        static function add(x:int, y:int) : int {
                return x + y;
        }

        static function add(x:string, y:string) : string {
                return x + y;
        }
    }



