package Inline::MzScheme;
$Inline::MzScheme::VERSION = '0.01';
@Inline::MzScheme::ISA = qw(Inline);

use strict;

use Inline ();
use Scalar::Util       ();
use Language::MzScheme ();
use Carp qw(croak confess);

=head1 NAME

Inline::MzScheme - Inline module for the PLT MzScheme interpreter

=head1 SYNOPSIS

    use Inline MzScheme => '(define (square x) (* x x))';
    print square(10); # 100

=head1 DESCRIPTION

This module allows you to add blocks of Scheme code to your Perl
scripts and modules.  Any procedures you define in your Scheme code
will be available in Perl.

For information about handling MzScheme data in Perl, please see
L<Language::MzScheme>.  This module is mostly a wrapper around
L<Language::MzScheme::scheme_eval_string> with a little auto-binding
magic for procedures and input variables.

=cut

# register for Inline
sub register {
    return {
	language => 'MzScheme',
	aliases  => ['MZSCHEME'],
	type     => 'interpreted',
	suffix   => 'go',
    };
}

# check options
sub validate {
    my $self = shift;

    while (@_ >= 2) {
	my ($key, $value) = (shift, shift);
	croak("Unsupported option found: \"$key\".");
    }
}

# required method - doesn't do anything useful
sub build {
    my $self = shift;

    # magic dance steps to a successful Inline compile...
    my $path = "$self->{API}{install_lib}/auto/$self->{API}{modpname}";
    my $obj  = $self->{API}{location};
    $self->mkpath($path)                   unless -d $path;
    $self->mkpath($self->{API}{build_dir}) unless -d $self->{API}{build_dir};

    # touch my monkey
    open(OBJECT, ">$obj") or die "Unable to open object file: $obj : $!";
    close(OBJECT) or die "Unable to close object file: $obj : $!";
}

my $block;
$block = qr/(\((?:(?>[^()]+)|(??{$block}))*\))/;

# load the code into the interpreter
sub load {
    my $self = shift;
    my $code = $self->{API}{code};
    my $pkg  = $self->{API}{pkg} || 'main';
    my $env  = Language::MzScheme::scheme_basic_env();

    foreach my $chunk (split($block, $code)) {
        $chunk =~ /\S/ or next;
	my $result = eval {
            Language::MzScheme::scheme_eval_string($chunk, $env);
        };
	croak "Inline::MzScheme: Problem evaluating code:\n$chunk\n\nReason: $@"
	  if $@;
	croak "Inline::MzScheme: Problem evaluating code:\n$chunk\n"
	  unless $result;    # == 1;
    }

    # look for possible global defines
    while ($code =~ /\bdefine\s+\W*(\S+)/g) {
	my $name = $1;

	# try to lookup a procedure object
	my $proc = eval {
            Language::MzScheme::scheme_eval_string($name, $env)
        } or next;

        no strict 'refs';
        *{"${pkg}::$name"} = sub {
            my $list = join(
                ' ',
                map {
                    Scalar::Util::looks_like_number($_) ? $_ : do {
                        my $str = $_;
                        $str =~ s/(?:["\\])/\\/g;
                        qq("$str");
                    };
                } @_
            );

            my $out = Language::MzScheme::scheme_make_string_output_port();
            my $rv = Language::MzScheme::scheme_eval_string("($name $list)", $env);
            Language::MzScheme::scheme_display($rv, $out);
            return Language::MzScheme::scheme_get_string_output($out);
        };
    }

}

# no info implementation yet
sub info { }

1;

__END__

=head1 ACKNOWLEDGEMENTS

Thanks to Sam Tregar's L<Inline::Guile> for showing me how to do this.

=head1 SEE ALSO

L<Language::MzScheme>, L<Inline>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
