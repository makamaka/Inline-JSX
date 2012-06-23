use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test', CLASS_PREFIX => 'JSX::';

my $p = JSX::Point->new();

isa_ok( $p, 'JSX::Point' );

is( $p->x, 0 );
is( $p->y, 0 );
is( $p->dump, '(0,0)' );

$p = JSX::Point->new(1,2);
is( $p->x, 1 );
is( $p->y, 2 );
is( $p->dump, '(1,2)' );

$p = JSX::Point->new( $p );
is( $p->x, 1 );
is( $p->y, 2 );
is( $p->dump, '(1,2)' );

$p->set(3,4);
is( $p->dump, '(3,4)' );

$p->set( JSX::Point->new(10, 20) );
is( $p->dump, '(10,20)' );

eval { JSX::Point->new( 1,2,3 ) };
ok( $@ =~ /mismatch/, 'mismatch' );

$p = JSX::Point->new();
eval { $p->z };
ok( $@, 'no property' );

done_testing;
    
__END__
__JSX__

class Point {
    var x = 0;
    var y = 0;

    function constructor() {
    }

    function constructor(x : number, y : number) {
        this.set(x, y);
    }

    function constructor(other : Point) {
        this.set(other);
    }

    function set(x : number, y : number) : void {
        this.x = x;
        this.y = y;
    }

    function set(other : Point) : void {
        this.x = other.x;
        this.y = other.y;
    }

    function dump() : string {
        return '(' + new Number( this.x ).toString() + ',' + new Number( this.y ).toString() + ')';
    }

}


