use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

is( Test->echoBool('a'), 1);
is( Test->echoBool(1), 1);
is( Test->echoBool(0), '');
is( Test->echoBool(''), '');
eval { Test->echoBool([]) };
ok( $@ );

is( Test->reverseBool('a'), '');
is( Test->reverseBool(1), '');
is( Test->reverseBool(0), 1);
is( Test->reverseBool(''), 1);

done_testing;
    
__END__
__JSX__

class Test {

    static function echoBool (b:boolean) : boolean {
        return b;
    }

    static function reverseBool (b:boolean) : boolean {
        return !b;
    }

}

