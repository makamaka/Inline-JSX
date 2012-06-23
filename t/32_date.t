use strict;
use Test::More;
use t::Utils;

my $fh;
my $out = '';
BEGIN { open($fh, '>>', \$out) or die $!; }

use Inline JSX => 'DATA', CONSOLE_STDOUT => $fh, DIRECTORY => '_Inline_test';

use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

my $date = Test->new->date;

isa_ok( $date, 'Time::Piece' );

my $date2 = Test->echoDate( $date );

isa_ok( $date2, 'Time::Piece' );
is( $date2->ymd, $date->ymd );

_Main->main([]);

my $hms = $date->hms;
my $log = (split/\n/, $out)[0];
like( $date, qr/$hms/, $date );

done_testing;
    
__END__
__JSX__

class Test {
    var date = new Date();

    static function echoDate (d:Date) : Date {
        return d;
    }
}

class _Main {
    static function main (args:string[]) : void {
        log (new Test()).date;
    }
}


