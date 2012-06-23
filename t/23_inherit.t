use strict;
use Test::More;
use t::Utils;

use Inline JSX => 'DATA', DIRECTORY => '_Inline_test';

my $admin = Admin->new("Sakura");

isa_ok( $admin, 'Admin' );
is( $admin->name, 'Sakura' );
is( $admin->say, 'My name is Sakura. I am an admin.' );

my $user = User->new("Isami");
isa_ok( $user, 'User' );
is( $user->name, 'Isami' );
is( $user->say, 'My name is Isami.' );


done_testing;
    
__END__
__JSX__

class Admin extends User {
    var is_root = 1;

    function constructor(x:string) {
        this.name = x;
    }

    override function say () : string {
        return super.say() + " I am an admin.";
    }

}

class User {
    var name = 'anonymous';

    function constructor() {
    }

    function constructor(x:string) {
        this.name = x;
    }

    function say() : string {
        return 'My name is ' + this.name + '.';
    }

}


