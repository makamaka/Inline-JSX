use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

use Data::Dumper;
local $Data::Dumper::Maxdepth = 3;

my $foo = Test->createFoo;

isa_ok($foo, 'Foo');
is $foo->foo, 'foo';

my $bar = Test->createBar;
is $bar->bar, 'bar';

$bar->x('hoge');
is $bar->bar, 'hoge';


done_testing;
    
__END__
__JSX__

class Foo {
    function constructor () {}
    function foo () : string { return "foo"; }
}

class Bar {
    var x = 'bar';
    function constructor () {}
    function bar () : string { return this.x; }
}

class Test {
    static function createFoo () : Foo {
        return new Foo;
    }

    static function createBar () : Bar {
        return new Bar;
    }
}


