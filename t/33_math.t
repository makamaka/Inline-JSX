use strict;
use Test::More;
use t::Utils;

my $fh;
my $out = '';
BEGIN { open($fh, '>>', \$out) or die $!; }

use Inline JSX => 'DATA', CONSOLE_STDOUT => $fh, DIRECTORY => '_Inline_test';

is( Test->testMath( 3.1415 ), 3 );
like( Test->testMath( 'pi' ), qr/^3\.1415/ );
is( Test->testMath( 'foo' ), undef );

_Main->main([]);

my @tests = split/\n/, $out;

like $tests[0], qr/^3.1415/;
is   $tests[1], 1;
like $tests[2], qr/^3.1415/;
is   $tests[3], 'undefined';

done_testing;
    
__END__
__JSX__

class Test {
    static function testMath (n:number) : int {
        return Math.floor(n);
    }

    static function testMath (s:string) : MayBeUndefined.<number> {
        if ( s == 'pi' ) return Math.PI;
        return undefined;
    }
}

class _Main {
    static function main(args:string[]) : void {
        log Math.PI;
        log Test.testMath( 1.23 );
        log Test.testMath( 'pi' );
        log Test.testMath( 'hoge' );
    }
}


