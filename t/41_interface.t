use strict;
use Test::More;
use t::Utils;

my $fh;
my $out = '';
BEGIN { open($fh, '>>', \$out) or die $!; }

use Inline JSX => 'DATA', CONSOLE_STDOUT => $fh, DIRECTORY => '_Inline_test';

_Main->main([]);

my $ani = Animal->new;
my $bat = Bat->new;
my $bee = Bee->new;

isa_ok( $bat, 'Bat' );
isa_ok( $bat, 'Animal' );
isa_ok( $bee, 'Bee' );
isa_ok( $bee, 'Insect' );

$bat->eat;
$bat->fly;

my @tests = split/\n/, $out;
is $tests[0], 'An animal is eating!';
is $tests[1], 'A bat is flying!';
is $tests[2], 'A bee is flying!';

is $tests[3], 'An animal is eating!';
is $tests[4], 'A bat is flying!';

ok( Test->setAnimal( $ani ) );
ok( Test->setAnimal( $bat ) );

done_testing;

__END__
__JSX__

// from JSX tutorial in the official site

interface Flyable {
    abstract function fly() : void;
}

abstract class Animal {
    function eat() : void {
      log "An animal is eating!";
    }
}

class Bat extends Animal implements Flyable {
    override function fly() : void {
        log "A bat is flying!";
    }
}

abstract class Insect {
}

class Bee extends Insect implements Flyable {
    override function fly() : void {
        log "A bee is flying!";
    }
}

class Test {
    static function setAnimal (a:Animal) : boolean {
        return true;
    }
}

class _Main {

    static function main(args : string[]) : void {
        // fo bar
        var bat = new Bat();

        var animal : Animal = bat; // OK. A bat is an animal.
        animal.eat();

        var flyable : Flyable = bat; // OK. A bat can fly
        flyable.fly();

        // for Bee
        var bee = new Bee();

        flyable = bee; // A bee is also flyable
        flyable.fly();
    }
}

