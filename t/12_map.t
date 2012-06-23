use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

is( Test->setHV({}), 0);
is( Test->setHV({"foo"=>1}), 1);
is( Test->setHV({"foo"=>1, "bar"=>3}), 2);
eval { Test->setHV({"foo"=>"a"}) };
ok( $@ );

my $map = Test->createMap();

is_deeply( $map, {foo=>1} );

is_deeply( Test->toMap('bar', 1), {'bar'=>1} );

done_testing;
    
__END__
__JSX__

class Test {

    static function setHV (m:Map.<int>) : int {
        var cnt = 0;
        for (var k in m) {
            cnt++;
        }
        return cnt;
    }

    static function createMap () : Map.<number> {
        var v = {"foo":1};
        return v;
    }

    static function toMap (k:string, n:boolean) : Map.<boolean> {
        var m : Map.<boolean>;
        (m = {} : Map.<boolean>)[ k.toString() ] = n;
        return m;
    }

}

