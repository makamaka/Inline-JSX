use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

use Data::Dumper;
local $Data::Dumper::Maxdepth = 2;


is_deeply( Test->double( sub { $_[0] * 2 }, [1,2] ), [2,4] );
is_deeply( Test->double( sub { $_[0] . $_[0] }, ['a','b'] ), ['aa','bb'] );

eval { Test->double('code', [1]) };
ok( $@ =~ /mismatch/ );

my $func = Test->foo(
    sub {
        my ( $str ) = @_;
        return sub { $_[0] . $str };
    },
    ' bar!',
);

is $func->("foo"), 'foo bar!';

eval { Test->foo() };
ok( $@ =~ /mismatch/ );

eval { Test->foo( Inline::JSX::null() ) };
ok( !$@ );

done_testing;
    
__END__
__JSX__

class Test {

    static function double (f:function (:int) : int, a:int[]) : int[] {
        var ret = [] : int[];
        for ( var i = 0; i < a.length; i++ ) {
            ret[i] = f( a[i] );
        }
        return ret;
    }

    static function double (f:function (:string) : string, a:string[]) : string[] {
        var ret = [] : string[];
        for ( var i = 0; i < a.length; i++ ) {
            ret[i] = f( a[i] );
        }
        return ret;
    }

    static function foo (f:function (:string) : function(:string):string, s:string) : function(:string):string {
        return f(s);
    }

    static function foo (f:function () : void) : void {
    }

}

