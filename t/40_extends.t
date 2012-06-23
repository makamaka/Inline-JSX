use strict;
use Test::More;
use t::Utils;

my $fh;
my $out = '';
BEGIN { open($fh, '>>', \$out) or die $!; }

use Inline JSX => 'DATA', CONSOLE_STDOUT => $fh, DIRECTORY => '_Inline_test';

my $ani = Animal->new;
my $bat = Bat->new;
my $bee = Bee->new;

isa_ok($ani, 'Object');
isa_ok($ani, 'Animal');
isa_ok($bat, 'Bat');
isa_ok($bat, 'Animal');
isa_ok($bat, 'Object');
isa_ok($bee, 'Bee');
isa_ok($bee, 'Insect');
isa_ok($bee, 'Object');

done_testing;

__END__
__JSX__

// from JSX tutorial in the official site


abstract class Creature {
}

abstract class Animal extends Creature {
}

class Bat extends Animal {
}

abstract class Insect extends Creature {
}

class
    Bee
        extends
            Insect
   {
   }


