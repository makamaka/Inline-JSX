use strict;
use Test::More;
use t::Utils;

my $fh;
my $out = '';
BEGIN { open($fh, '>>', \$out) or die $!; }

use Inline JSX => 'DATA', CONSOLE_STDOUT => $fh, DIRECTORY => '_Inline_test';

use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

my $reg = Test->new->regexp;
my @match = 'daa' =~ $reg;
is( @match, 0 );

@match = 'bac' =~ $reg;
is( $match[0], 'a' );
is( $match[1], 'c' );

_Main->main([]);

my @tests = split/\n/, $out;

is( @tests, 1 );
is $tests[0], '/[abc](a)/i';

$reg = Test->echoRegExp( qr/^([dbc]d)(.)/ );

@match = 'bac' =~ $reg;
is( @match, 0 );

@match = 'cdc' =~ $reg;
is( $match[0], 'cd' );
is( $match[1], 'c' );

#print Dumper(Test->echoRegExp( qr/[abc]d/ ));
#print Dumper(qr/[abc]d/);
#print Dumper(Test->new->regexp);


done_testing;
    
__END__
__JSX__

class Test {
    var regexp = new RegExp('[abc](.)(.)', 'i');

    static function echoRegExp (reg:RegExp) : RegExp {
        return reg;
    }
}

class _Main {
    static function main (args:string[]) : void {
        var reg = new RegExp('[abc](a)', 'i');
        log reg;
    }
}


