require 5.008003;
use strict;
use ExtUtils::MakeMaker;

my $jsx = '';
if ( defined $ENV{ PERL_INLINE_JSX_JSX_PATH } ) {
    if ( -e $ENV{ PERL_INLINE_JSX_JSX_PATH } ) {
        $jsx = $ENV{ PERL_INLINE_JSX_JSX_PATH };
    }
    else {
        print STDERR "$ENV{ PERL_INLINE_JSX_JSX_PATH } is not executable. so checking system...\n";
    }
}

unless ( $jsx ) {
    for ( split( /:/, $ENV{ PATH } ) ) {
        my $path = $_ . '/jsx';
        if ( -e $path ) {
            $jsx = $path;
            next;
        }
    }
}

if ( !$ENV{SKIP_JSX_CHECK} and $jsx ) {
    print STDERR "jsx is found. - $jsx\n";
    eval {
        require IPC::Run;
        my @cmd = ( $jsx, '--', '-' );
        my ( $in, $out, $err );
        $in = 'class Test { static function foo () : void {} }';
        IPC::Run::run( \@cmd, \$in, \$out, \$err );
        if ( $err ) {
            print STDERR "Error: your jsx has some problem. ($err)\n";
            exit;
        }
        elsif ( $out !~ /var Test\$foo\$/ ) { # var declared?  - git commit 293db53787
            print STDERR "Error: your jsx is older. Please install newer.\n";
            exit;
        }
    };
    if ( $@ ) {
        print STDERR $@;
        exit;
    }
    open(my $fh, '>', './t/jsx_path.pl') or die $!;
    print $fh "q{$jsx};";
}
elsif ( !$ENV{SKIP_JSX_CHECK} ) {
    print STDERR "Error: Can't find jsx for tests. Please check your library path to jsx.";
    print STDERR " You can also set the environment variable PERL_INLINE_JSX_JSX_PATH directly.";
    print STDERR " And you can set SKIP_JSX_CHECK=1 for no checking jsx.\n";
    exit;
}


WriteMakefile(
    'NAME'          => 'Inline::JSX',
    'VERSION_FROM'  => 'lib/Inline/JSX.pm', # finds $VERSION
    'PREREQ_PM'     => {
              'Test::More'  => 0,
              'Inline'      => '0.50',
              'JE'          => '0.059',
              'Time::Piece' => 0,
              'IPC::Run'    => 0,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Inline/JSX.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>') : ()),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),

    ( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
            resources => {
                repository  =>      'http://github.com/makamaka/Inline-JSX',
            },
        } ) : ()
    ),
);
