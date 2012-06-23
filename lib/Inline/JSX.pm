package Inline::JSX;

use strict;
use warnings;

use base qw(Inline);
use JE;
use Carp ();
use Scalar::Util qw(blessed);
use Data::Dumper;

our $VERSION = '0.02';

use constant DEBUG         => $ENV{PERL_INLINE_JSX_DEBUG}         ? 1 : 0;
use constant SHOW_HEADCODE => $ENV{PERL_INLINE_JSX_SHOW_HEADCODE} ? 1 : 0;
use constant SHOW_MAINCODE => $ENV{PERL_INLINE_JSX_SHOW_MAINCODE} ? 1 : 0;

#
# Inline APIs
#

sub register {
    return {
        language => 'JSX',
        aliases  => [qw/jsx gfx/],
        type     => 'interpreted',
        suffix   => 'pl',
    };
}

sub validate {
    my $self = shift;
    my $islm = $self->{ ILSM }= {};

    while ( @_ ) {
        my ( $key, $val ) = splice( @_, 0, 2 );
        $islm->{ $key } = $val;
    }

    $islm->{ CLASS_PREFIX } ||= '';

    if ( $islm->{ CLASS_PREFIX } and $islm->{ CLASS_PREFIX } !~ /^[_a-zA-Z][_a-zA-Z:]+$/ ) {
        Carp::croak("Invalid class prefix '$islm->{ CLASS_PREFIX }'");
    }

}

our $CONSTRUCTOR  = {};
our $CLASS_PREFIX = '';

sub build {
    my ( $self ) = @_;
    my $compiled = $self->compile_jsx( $self->{ API }->{ code } );
    my $je       = JE->new;
    #open(my $dump, '>', './dumped_js.pl'); print $dump Dumper($je->compile($out)); close($dump);
    $je->eval( $compiled );
    if ($@) {
        Carp::croak $@;
    }

    # 今のところ無理ぽ
    # $Data::Dumper::Deparse = 1;
    # $perlcode_head = 'use JE; our $VAR1;' . Dumper($je);
    # $perlcode_head .= 'my $je = $VAR1;' . "\n";
    local $CLASS_PREFIX = $self->{ ILSM }->{ CLASS_PREFIX };
    #local $Data::Dumper::Maxdepth = 3;
    #print Dumper( ${$je->prop('JSX')->prop('require')}->{scope}->[1] );
    my $scope      = ${$je->prop('JSX')->prop('require')}->{scope}->[1];
    my $class_map  = $scope->{'$__jsx_classMap'};
    #print Dumper( [ grep { $_ !~ /^(-|\$__jsx)/  } keys %$scope  ] );
    my @classnames = (
        map { my $n = $_; map { [$n=>$_] } @{${$$class_map->{props}->{$n}}->{keys}} } @{ $$class_map->{keys} }
    );
    my @static_funcs;
    for ( @classnames ) {
        my ( $source, $class ) = @$_;

        if ( $class =~ /\$/ ) { # constructor
            push @static_funcs, [ $source, $class ];
            next;
        }

        push @static_funcs,
            map  { $class . '$' . $_ }
            grep { $_ ne 'arguments' and $_ ne 'prototype' } @{ ${$scope->{ $class }}->{keys} };
    }

    my $isa_rel  = $self->detect_inherited( $self->{ API }->{ code } );
    my $perlcode = "{ package ${CLASS_PREFIX}Object; }\n";
    my %code;

    # class method
    for my $_ ( @classnames ) {
        my ($source, $prop) = @$_;

        next if ( $prop =~ /\$/ );

        my $p = $je->prop('JSX')->method('require', $source)->prop($prop)->construct;
        my $class = $CLASS_PREFIX . $prop;

        if ( my $super = $isa_rel->{ $prop } ) {
            $perlcode .= "{ package $class; our \@ISA = ('$CLASS_PREFIX$super'); }\n";
        }
        else {
            $perlcode .= "{ package $class; our \@ISA = ('${CLASS_PREFIX}Object'); }\n";
        }

        $perlcode .= _make_autoload_str( $class );

        for my $k ( $p->keys ) { # properties

            next if ( $k =~ /^\$__jsx_implements_/ ); # for interface

            my ( $method, $types ) = split(/\$/, $k, 2);
            my $class_method = "$class\::$method";
            my $types_str    = _dump_to_str( parse_type( $types )->[1] );
            DEBUG && print "class method | $class -> $method : $types\n";
            unless ( $code{ $class_method } ) {
                $code{ $class_method } = "sub $class_method {\n";
                $code{ $class_method } .= "    my \$o = shift;\n";
                $code{ $class_method } .= '    my $argstypes = encode_argstype( @_ );' ."\n";
            }

            # type checking
            my @args = _make_passing_args_str( @{ parse_type( $types )->[1] } );
            $code{ $class_method } .= "    if ( check_types( $types_str, \$argstypes ) ) {" . "\n";
            $code{ $class_method } .= '        '. _make_call_func_str( '$$o', $k, @args ) . "\n";
            $code{ $class_method } .= "    }\n";
        }
    }

    # static function and constructor
    for ( @static_funcs ) {
        my ( $source, $prop ) = ref $_ ? (@{$_}) : (undef, $_);
        my @props = $source ? split(/\$/, $prop, 2) : split(/\$/, $prop, 3);
        push @props, '' if $prop =~ /\$$/;

        my $class  = shift @props;
        my $method = $source ? 'new' : shift @props;
        my $types  = shift @props || '';

        next unless $class;

        $class = $CLASS_PREFIX . $class;
        DEBUG && $method eq 'new' && print "constructor  | $class -> $method : $types\n";
        DEBUG && $method ne 'new' && print "static func  | $class -> $method : $types\n";

        my $class_method = "$class\::$method";

        unless ( $code{ $class_method } ) {
            $code{ $class_method } = "sub $class_method {\n";
            $code{ $class_method } .= '    my $self = shift;' . "\n";
            $code{ $class_method } .= "    my \$m = \$jsx->method('require', '$source');\n" if $method eq 'new';
            $code{ $class_method } .= '    my $argstypes = encode_argstype( @_ );' ."\n";
        }

        my $types_str = _dump_to_str( parse_type( $types )->[1] );
        $code{ $class_method } .= "    if ( check_types( $types_str, \$argstypes ) ) {" . "\n";

        # type checking
        my @args = _make_passing_args_str( @{ parse_type( $types )->[1] } );

        if ( $method eq 'new' ) { # constructor
            $CONSTRUCTOR->{ $prop } = 1;
            $code{ $class_method } .= '        ' . _make_call_constructor_str( '$m', $class, $prop, @args ) . "\n";
        }
        else { # static function
            $code{ $class_method } .= '        ' . _make_call_static_func_str( '$scope', $prop, @args ) . "\n";
        }
        $code{ $class_method } .= "    }\n";
    }

    for my $lines ( values %code ) {
        $perlcode .= $lines;
        $perlcode .= "    Carp::croak('argument type mismatch');\n";
        $perlcode .= "}\n";
    }

    my $perlcode_head = _make_init_str( $compiled, "'construct_map'" => _dump_to_str( $CONSTRUCTOR ) );

    SHOW_HEADCODE && print $perlcode_head,"\n";
    SHOW_MAINCODE && print $perlcode,"\n";

    my $path = $self->{ API }->{ install_lib } . '/auto/' . $self->{ API }->{modpname};
    my $file = $self->{ API }->{ location };

    $self->mkpath( $path ) unless -d $path;

    open( my $fh, '>', $file ) or Carp::croak("Can't write $file for output.\n$!");
    print $fh $perlcode_head;
    print $fh $perlcode;
    close $fh;
}

sub load {
    my ( $self ) = @_;
    my $file = $self->{ API }->{ location };

    open( my $fh, '<', $file ) or Carp::croak("Can't open $file for load.\n$!");
    my $code = do { local $/; <$fh> };
    eval $code;
    if ( $@ ) {
        unlink $file or Carp::carp($!);
        Carp::croak( DEBUG ? $@ . $code : $@ );
    }

    $Inline::JSX::CLASS_PREFIX = $self->{ ILSM }->{ CLASS_PREFIX };

    for ( qw/STDOUT STDERR/ ) {
        no strict 'refs';
        my $std_foo = 'Inline::JSX::Console::' . lc($_);
        if ( my $log = $ENV{ "PERL_INLINE_JSX_CONSOLE_$_" } || $self->{ ILSM }->{ "CONSOLE_$_" } ) {
            if ( ref $log ) {
                *{$std_foo} = $log;
            }
            else {
                open ( my $fh, '>>', $log ) or Carp::croak( $! );
                *{$std_foo} = $fh;
            }
        }
        else {
            *{$std_foo} = *{$_};
        }
    }
}

sub info { }

#
#
#

sub search_jsx_path {
    my ( $o ) = @_;
    my @paths = $ENV{ PATH } ? ( map {$_.'/jsx'} split(/:/, $ENV{ PATH }) ) : ();
    for my $p ( $ENV{ PERL_INLINE_JSX_JSX_PATH }, @paths, $ENV{HOME} . '/bin/jsx', './bin/jsx' ) {
        next unless $p;
        if ( -e $p ) {
            return $p;
        }
    }
    return '';
}

sub compile_jsx {
    my ( $self, $code ) = @_;
    my $jsx = $self->{ ILSM }->{ JSX_PATH } || $self->search_jsx_path();
    my $lib = $ENV{ PERL_INLINE_JSX_LIB_PATH }   || $self->{ ILSM }->{ LIB_PATH };

    Carp::croak("jsx($jsx) is not executable.") unless -e $jsx;

    require IPC::Run;
    my @cmd = ( $jsx);
    push @cmd, '--add-search-path', $lib if $lib;
    push @cmd, '--', '-';

    my ( $in, $out, $err );
    $in = $code;
    IPC::Run::run( \@cmd, \$in, \$out, \$err );

    if ( $err ) {
        Carp::croak( $err );
    }

    return $out;
}

sub detect_inherited {
    my ( $self, $code ) = @_;
    my %isa;
    # half way
    while ( $code =~ /\s*class\s+(\w+)\s+extends\s+(\w+)/g ) {
        $isa{ $1 } = $2;
    }
    return \%isa;
}

#
#
#

sub parse_type { # return a list ref holds a consumed str length and a parsed structure
    my ($str, $once) = @_;
    my $i = 0;
    my @types;

    while ( my $ch = substr( $str, $i, 1 ) ) {
        if ( $ch eq 'A' or $ch eq 'H' or $ch eq 'U' ) {
            my $ret = parse_type( substr( $str, $i + 1 ), 1 );
            push @types, [ $ch => @{$ret->[1]} ];
            $i += 1 + $ret->[0];
        }
        elsif ( $ch eq 'L' ) { # L......$
            substr( $str, $i ) =~ /L(.+?)\$/;
            push @types, [ 'L' => $1  ];
            $i += 2 + length $1;
        }
        elsif ( $ch eq 'F' ) { # F$......$
            my @args;
            $i++; # start with '$'
            PARSE: {
                my $ret = parse_type( substr( $str, $i + 1 ), 1 );
                push @args, $ret->[1]->[0];
                $i += $ret->[0];
                last PARSE if substr( $str, $i + 1, 1 ) eq '$';
                last PARSE if $i >= length $str;
                redo PARSE;
            }
            $i += 2;
            push @types, [ $ch => @args ];
        }
        else {
            push @types, $ch;
            $i++;
        }
        last if $once;
    }

    return [$i, \@types ];
}

#
# CODE GENERATOR
#

sub _make_init_str {
    my ( $out, @args ) = @_;
    my $perlcode_head;
    $perlcode_head .= "use strict; use B;\n";
    $perlcode_head .= "Inline::JSX->init_je(" . join( ', ', @args ) . ");\n";
    $perlcode_head .= q/my $je = Inline::JSX::JE->new; $je->eval(<<'______JSCODE');/ . "\n";
    $perlcode_head .= $out . "\n______JSCODE\n\n"; 
    $perlcode_head .= q/my $jsx = $je->prop('JSX');/. "\n";
    $perlcode_head .= q/my $scope = ${$jsx->prop('require')}->{scope}->[1];/. "\n";
    return $perlcode_head;
}

sub _make_autoload_str {
    my ( $class ) = @_;
    my $perlcode = sprintf( <<'CODE', $class );
{
    package %s;
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $method = $AUTOLOAD;;
        $method =~ s{.*::}{};;
        return if $method eq 'DESTROY';
        no strict 'refs';
        Carp::croak("No property '$method'") unless exists $${$_[0]}->{props}->{ $method };
        *{"$method"} = sub {
            my $o = shift;
            if ( @_ ) {
                $$o->prop( $method => Inline::JSX::convert_je_for_x($$o->global, $_[0]) );
            }
            else {
                Inline::JSX::convert_je_to_perl( $$o->prop( $method ) );
            }
        };
        goto &$AUTOLOAD;
    }
}
CODE

    return $perlcode;
}

sub _make_passing_args_str {
    my ( @types ) = @_;
    my @args;
    my $i = 0;

    for my $type ( @types ) {
        if ( $type eq 'I' or $type eq 'N' ) {
            push @args, sprintf('JE::Number->new($je,$_[%d])', $i++);
        }
        elsif ( $type eq 'B' ) {
            push @args, sprintf('JE::Boolean->new($je,$_[%d])', $i++);
        }
        elsif ( $type eq 'S' ) {
            push @args, sprintf('JE::String->new($je,$_[%d])', $i++);
        }
        elsif ( $type eq 'X' ) {
            push @args, sprintf('Inline::JSX::convert_je_for_x($je, $_[%d])', $i++);
        }
        elsif ( $type->[0] eq 'L' ) {
            if ( $type->[1] eq 'RegExp' ) {
                push @args, sprintf('Inline::JSX::convert_nullable_to_je($je,$_[%d] => "L-RegExp")', $i++);
            }
           elsif ( $type->[1] eq 'Date' ) {
                push @args, sprintf('Inline::JSX::convert_nullable_to_je($je,$_[%d] => "L-Date")', $i++);
            }
            else {
                push @args, sprintf('Inline::JSX::convert_nullable_to_je($je,$_[%d] => "L")', $i++);
            }
        }
        elsif ( $type->[0] eq 'U' ) {
            my $defined_type = ( _make_passing_args_str($type->[1]) )[0];
            $defined_type =~ s/\$_[\d+]/\$_[$i]/;
            push @args, sprintf('defined $_[%d] ? %s : $je->undefined', $i, $defined_type);
            $i++;
        }
        elsif ( $type->[0] eq 'A' ) {
            push @args, sprintf('Inline::JSX::convert_nullable_to_je($je,$_[%d] => "A")', $i++);
        }
        elsif ( $type->[0] eq 'H' ) {
            push @args, sprintf('Inline::JSX::convert_nullable_to_je($je,$_[%d] => "H")', $i++);
        }
        elsif ( $type->[0] eq 'F' ) {
            push @args, sprintf('Inline::JSX::convert_nullable_to_je($je,$_[%d] => "F")', $i++);
        }
        else {
            Carp::croak("Invaid argument type");
        }
    }

    return @args;
}

sub _make_call_static_func_str {
    my ( $obj, $prop, @args ) = @_;
    return sprintf( 'return convert_je_to_perl( %s->{\'%s\'}->());', $obj, $prop ) unless @args;
    return sprintf( 'return convert_je_to_perl( %s->{\'%s\'}->(%s));', $obj, $prop, join(', ', @args) );
}

sub _make_call_func_str {
    my ( $obj, $prop, @args ) = @_;
    return sprintf( 'return convert_je_to_perl( %s->method(\'%s\'));', $obj, $prop ) unless @args;
    return sprintf( 'return convert_je_to_perl( %s->method(\'%s\' => %s));', $obj, $prop, join(', ', @args) );
}

sub _make_call_constructor_str {
    my ( $obj, $class, $prop, @args ) = @_;
    return sprintf( 'return bless \do{%s->prop(\'%s\')->construct()}, \'%s\';', $obj, $prop, $class ) unless @args;
    return sprintf( 'return bless \do{%s->prop(\'%s\')->construct(%s)}, \'%s\';', $obj, $prop, join(', ', @args), $class );
}

sub _dump_to_str {
    local $Data::Dumper::Indent = 0;
    my $data = $_[0];
    my $str  = Data::Dumper::Dumper($data);
    $str =~ s/^\$VAR1 = //;
    $str =~ s/;$//;
    return $str;
}

#
# RUNTIME
#

sub encode_argstype {
    my @objs  = @_;
    my @types;
    # TODO: expansion in case of JE Object
    for my $obj ( @objs ) {

        if ( !defined $obj ) {
            push @types, 'U';
            next;
        }
        elsif ( blessed $obj ) {
            my $classname = ref $obj;
            push @types, ['L', $obj];
            # exception of RegExp, Date, Math
            $types[-1]->[1] = $CLASS_PREFIX . 'RegExp' if $classname eq 'Regexp';
            $types[-1]->[1] = $CLASS_PREFIX . 'Date'   if $classname eq 'Time::Piece';
            next;
        }

        my $bobj  = B::svref_2object( ref $obj ? $obj : \$obj);
        my $flags = $bobj->FLAGS;

        if ( $bobj->isa('B::AV') ) {
            push @types, ['A',
                scalar(@$obj) ? @{ encode_argstype( (@{$obj})[0] ) } : '*'
            ]; # TODO: check all items
        }
        elsif ( $bobj->isa('B::HV') ) {
            push @types, ['H',
                scalar(%{$obj}) ? @{ encode_argstype( (values %{$obj})[0] ) } : '*'
            ]; # TODO: check all items
        }
        elsif ( $bobj->isa('B::CV') ) {
            push @types, 'F';
        }
        elsif ( $flags & B::SVp_NOK and !( $flags & B::SVp_POK ) ) {
            push @types, 'N';
        }
        elsif ( $flags & B::SVp_IOK and !( $flags & B::SVp_POK ) ) {
            push @types, 'I';
        }
        elsif ( $flags & B::SVp_POK ) {
            push @types, 'S';
        }
        elsif (  ref $obj eq 'REF' and $$$obj eq 'null' ) {
            push @types, '!';
        }
        else {
            push @types, '-'; # invalid type
        }
    }

    return \@types;
}

sub check_types { # validator!
    my ( $types, $args ) = @_;
    my @args  = @$args;
    my @types = @$types;
#local $Data::Dumper::Maxdepth = 3;
#print STDERR Dumper([$types, $args]);

    return scalar(@args) ? 0 : 1 unless @$types; # void type
    return 0 if ( @args != @types ); # args nunmber mismatch
    return 1 if ( $args[0] eq '*' ); # it is empty item, so consider valid.

    my $ret = 1;

    for my $arg ( @args ) {
        my $type  = shift @types;
        my ($check_arg, $nest_type, $nest_arg);

        if ( ref $type ) {
            ($type, $nest_type) = @$type;
        }

        ($check_arg, $nest_arg) = ref $arg ? @$arg : ($arg, undef);
        $check_arg ||= ''; $arg ||= '';

        if ( $type eq 'X' ) {
            next; # anything ok
        }
        elsif ( $type eq 'I' ) {
            $ret = $check_arg eq 'I' ? 1 : 0;
        }
        elsif ( $type eq 'N' ) {
            $ret = ($check_arg eq 'I' or $arg eq 'N') ? 1 : 0;
        }
        elsif ( $type eq 'S' ) {
            $ret = ($check_arg eq 'S') ? 1 : 0;
        }
        elsif ( $type eq 'A' ) {
            $ret = ( $check_arg =~ /^[A!]$/ and check_types([$nest_type], [$nest_arg]) ) ? 1 : 0;
        }
        elsif ( $type eq 'H' ) {
            $ret = ( $check_arg =~ /^[H!]$/ and check_types([$nest_type], [$nest_arg]) ) ? 1 : 0;
        }
        elsif ( $type eq 'B' ) {
            $ret = $check_arg =~ /^[INS]$/ ? 1 : 0; # ok, ok, perl boolean is easy...
        }
        elsif ( $type eq 'U' ) {
            $ret = ( $check_arg =~ /^[U!]$/ or check_types([$nest_type], [$arg]) ) ? 1 : 0;
        }
        elsif ( $type eq 'L' ) {
            my $classname = $CLASS_PREFIX . $nest_type;
            $ret = ($check_arg =~ /^[L!]$/
                and (ref $nest_arg ? $nest_arg->isa($classname) : $nest_arg eq $classname)) ? 1 : 0;
        }
        elsif ( $type eq 'F' ) {
            $ret = ( $check_arg =~ /^[F!]$/ ) ? 1 : 0;
        }
        else {
            $ret = 0;
        }

        return 0 unless $ret;
    }

    return 1;
}

sub convert_je_for_x { # cast a variant type
    my ( $je, $obj ) = @_;

    return $je->undefined if ( !defined $obj );
    return $je->null if ( ref $obj eq 'REF' and $$$obj eq 'null' );

    my $bobj  = B::svref_2object( ref $obj ? $obj : \$obj );
    if ( $bobj->isa('B::AV') ) {
        return $obj; # TODO?
    }
    elsif ( $bobj->isa('B::HV') ) {
        return JE::Object->new( $je, { value => { map { $_ => convert_je_for_x( $je, $obj->{ $_ } ) } keys %$obj } } );
    }

    my $flags = $bobj->FLAGS;
    if ( $flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK ) ) {
        return JE::Object::Number->new( $je, $obj );
    }
    elsif ( $flags & B::SVp_POK ) {
        return JE::Object::String->new( $je, $obj );
    }
    else{
        return $obj;
    }
}

sub convert_nullable_to_je {
    my ( $je, $obj, $type ) = @_;

    if ( ref $obj eq 'REF' and $$$obj eq 'null' ) {
        return $je->null;
    } 

    if ( $type eq 'A' ) {
        return JE::Object::Array->new( $je, $obj );
    }
    elsif ( $type eq 'H' ) {
        return JE::Object->new( $je, { value => $obj } );
    }
    elsif ( $type eq 'F' ) {
        return JE::Object::Function->new( $je, $obj );
    }
    elsif ( $type eq 'L' ) {
        return $$obj;
    }
    elsif ( $type eq 'L-RegExp' ) {
        return JE::Object::RegExp->new($je, $obj);
    }
    elsif ( $type eq 'L-Date' ) {
        return JE::Object::Date->new($je, "".$obj);
    }
    else {
        Carp::croak('Invalid type in converting to je');
    }

}

sub convert_je_to_perl { # je-perl mapping
    my ( $obj ) = @_;

    return $obj unless ref $obj and blessed $obj;

    if ( $obj->isa('JE::Undefined') ) {
        return undef;
    }
    elsif ( $obj->isa('JE::Null') ) {
        return undef;
    }

    my $class = $obj->class;
    if ( $class eq 'Array' ) {
        return [ map { convert_je_to_perl($_) } @{ $obj->value } ];
    }
    elsif ( $class eq 'Object' ) {
        return { map { $_ => convert_je_to_perl( $obj->prop($_) ) } $obj->keys };
    }
    elsif ( $class eq 'Number' or $class eq 'String' ) {
        return $obj->value;
    }
    elsif ( $class eq 'Blessed' ) {
        my $o = $obj;
        return bless \$o, $o->prop('__class__');
    }
    elsif ( $class eq 'Boolean' ) {
        return $obj->value;
        #return '' . $_[0];
    }
    elsif ( $class eq 'Function' ) {
        return $obj;
    }
    elsif ( $class eq 'RegExp' ) {
        return $obj->value;
    }
    elsif ( $class eq 'Date' ) {
        require Time::Piece;
        # it is difficult to set timezone with Time::Piece's public API in this case.
        # so I used _mktime that is a private method...
        #our $TIME ||= do{ require Time::Piece; Time::Piece::localtime() }; # for setting TZ
        #return $TIME->strptime( ''.$obj, '%a %b %d %H:%M:%S %Y %z' );
        #return $TIME->strptime( $obj->value - $obj->method('getTimezoneOffset') * 60, '%s' );
        return scalar Time::Piece->_mktime( $obj->value, 1 );
    }
    else {
        return $obj->value;
    }
}

sub init_je {
    my ( $class, %opt ) = @_;
    my $construct = \&JE::Object::Function::construct;
    no strict 'refs';
    no warnings;

    $CONSTRUCTOR = $opt{ construct_map } || {};

    *JE::Object::Function::construct = sub {
        my $name = ''. $_[0];
        my $obj = $construct->(@_);
        if ( $name =~ /function ([\w\$]+)/ && exists $CONSTRUCTOR->{ $1 } ) {
            my $class = $1; $class =~ s/\$.*$//;
            $obj->{__class__} = $class;
            bless $obj, 'Inline::JAX::JE::Objet';
        }
        return $obj;
    };

    return;
}

#
# Utils
#

our $null = \do{\'null'};#JE->new->null;
sub null { $null; }

#
# Util Classes
#

package Inline::JSX::JE;

our @ISA = ('JE');

sub new {
    my $self    = shift->SUPER::new( @_ );
    my $console = JE::Object->new($self);

    $console->new_method('log' => \&Inline::JSX::Console::log);
    $self->prop( 'console' => $console );

    return $self;
}


package Inline::JAX::JE::Objet;
our @ISA = ('JE::Object');

sub class { 'Blessed'; }


package Inline::JSX::Console;

use strict;

our $DUMP_NEST;

sub log {
    my ( $self, @objs ) = @_;
    my @ret;
    local $DUMP_NEST = 1 if @objs > 1;
    for my $obj ( @objs ) {
        push @ret, _dump( $obj );
    }
    print Inline::JSX::Console::stdout join(' ', @ret), "\n";
}

*info = *Inline::JSX::Console::log;

sub warn { # 'warn' does not exist in JSX syntax.
    my ( $self, @objs ) = @_;
    my @ret;
    local $DUMP_NEST = 1 if @objs > 1;
    for my $obj ( @objs ) {
        push @ret, _dump( $obj );
    }
    print Inline::JSX::Console::stderr join(' ', @ret), "\n";
}

*error = *Inline::JSX::Console::warn;

sub _dump {
    my $obj = $_[0];

    return 'null' if ( $obj->isa('JE::Null') );
    return 'undefined' if ( $obj->isa('JE::Undefined') );

    if ( $obj->class eq 'Array' ) {
        my @list =  @{$obj->value};
        return '[]' unless @list;
        local $DUMP_NEST = 1;
        return '[ ' . (join( ', ', map { _dump($_) } @list )) . ' ]';
    }
    elsif ( $obj->class eq 'Object' ) {
        my @keys = $obj->keys;
        return '{}' unless @keys;
        local $DUMP_NEST = 1;
        return '{ ' . (join( ', ', map { $_ . ': ' . _dump( $obj->prop($_) ) } @keys )) . ' }';
    }
    elsif ( $obj->class eq 'Blessed' ) {
        my @keys = grep { $_ ne '__class__' } $obj->keys;
        return '{}' unless @keys;
        return '{ ' . (join( ', ', map { $_ . ': ' . _dump( $obj->prop($_) ) } @keys )) . ' }';
    }
    elsif ( $obj->class eq 'Number' ) {
        return $obj->value;
    }
    elsif ( $obj->class eq 'String' ) {
        return $DUMP_NEST ? "'" . $obj->value . "'" : $obj->value;
    }
    elsif ( $obj->class eq 'Boolean' ) {
        return '' . $obj;
    }
    else {
        #use Data::Dumper;
        #local $Data::Dumper::Maxdepth = 3;
        #print Dumper($obj);
        return $obj->method('toString');
    }
}


1;
__END__

=pod

=head1 NAME

Inline::JSX - write Perl program in JSX

=head1 SYNOPSIS

    use Inline 'JSX';
    
    print Addition->add(1, 2), "\n";         # => 3
    print Addition->add('foo', 'bar'), "\n"; # => foobar
    print Addition->add('foo', 2), "\n";     # => error: type mismatch!
    
    __END__
    __JSX__
    class Addition {
        static function add(x:int, y:int) : int {
                return x + y;
        }

        static function add(x:string, y:string) : string {
                return x + y;
        }
    }

=head1 DESCRIPTION

Inline::JSX allows you to write JSX code in your Perl source code.

=head1 OPTIONS

=head2 JSX_PATH

Path to C<jsx> command.
You can set it with the environmental variable C<PERL_INLINE_JSX_JSX_PATH> too.

=head2 LIB_PATH

Path to jsx libray directory.
You can set it with the environmental variable C<PERL_INLINE_JSX_LIB_PATH> too.

=head2 CLASS_PREFIX

Prefix name of classes in Perl code.

    use Inline JSX => 'DATA', CLASS_PREFIX => 'JSX::';
    
    my $foo = JSX::Foo->new;
    
    __DATA__
    __JSX__
    
    class Foo {}

=head2 CONSOLE_SDOUT

Inline::JSX provides JSX's 'log' function that prints a dumped data to C<STDOUT>.
You can use this option with a file path or a file handle to print out to other file handle.

    use Inline JSX => Config => CONSOLE_STDOUT => $file_path;

You can set it with the environmental variables C<PERL_INLINE_JSX_CONSOLE_STDOUT> too.

=head1 MAPPING

       JSX      =>  Perl
    undefined       undef
    null            undef
    int, number     number
    string          string
    boolean         1 / !1 (true/false)
    Object          hash ref
    Array           array ref
    Function        JE::Object::Function
    new Class       blessed object
    RegExp          Regexp
    Date            Time::Piece

=head1 NOTE

JS's C<null> is converted to C<undef> in Perl
while this module supports C<Inline::JSX::null()> to pass C<null> to Perl-JSX function.
C<Inline::JSX::null()> just returns a reference of referecne of a string 'null'.;

JS's Date object is converted to L<Time::Piece>.

Not support generic type.

=head1 SEE ALSO

L<Inline>, L<JE>, L<http://jsx.github.com/>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut



