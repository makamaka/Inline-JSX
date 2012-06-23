use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', LIB_PATH => 't/jsx', DIRECTORY => '_Inline_test';

my $p = Point->new;

ok($p);
is( $p->dump, '(0,0)' );

done_testing;
    
__END__
__JSX__

import "point.jsx";

class _Main {
    static function main (args:string[]) : void {
        var p = new Point(2,3);
        log p;
    }
}


