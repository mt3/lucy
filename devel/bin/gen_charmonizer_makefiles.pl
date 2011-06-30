#!/usr/bin/perl

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use File::Find qw( find );
use FindBin;

-d "src" or die "Switch to the directory containg the charmonizer src/.\n";

my (@srcs, @tests, @hdrs);
my $license = "";

sub wanted {
    if (/\.c$/) {
        if (/^Test/) {
            push @tests, $File::Find::name;
        }
        else {
            push @srcs, $File::Find::name;
        }
    }
    elsif (/\.h$/) {
        push @hdrs, $File::Find::name;
    }
}

sub unix_obj {
    my @o = @_;
    s/\.c$/\$(OBJEXT)/, tr{\\}{/} for @o;
    return @o;
}

sub win_obj {
    my @obj = @_;
    s/\.c$/\$(OBJEXT)/, tr{/}{\\} for @obj;
    return @obj;
}

sub unix_tests {
    my @src = @_;
    my @test = map /\b(Test\w+)\.c$/, @src; # \w+ skips the Test.c entry
    $_ .= '$(EXEEXT)' for @test;
    my @obj = unix_obj @src;
    my $test_obj;
    @obj = grep /\bTest\$\(OBJEXT\)$/ ? ($test_obj = $_) && 0 : 1, @obj;
    my @block;
    push @block, <<EOT for 0..$#test;
$test[$_]: $test_obj $obj[$_]
	\$(LINKER) \$(LINKFLAGS) $test_obj $obj[$_] \$(LINKOUT)"\$@"
EOT
    return \@block, \@test;
}

sub win_tests {
    my @src = @_;
    my @test = map /\b(Test\w+)\.c$/, @src; # \w+ skips the Test.c entry
    $_ .= '$(EXEEXT)' for @test;
    my @obj = win_obj @src;
    my $test_obj;
    @obj = grep /\bTest\$\(OBJEXT\)$/ ? ($test_obj = $_) && 0 : 1, @obj;
    my @block;
    push @block, <<EOT for 0..$#test;
$test[$_]: $test_obj $obj[$_]
	\$(LINKER) \$(LINKFLAGS) $test_obj $obj[$_] \$(LINKOUT)"\$@"
EOT
    return \@block, \@test;
}

sub gen_makefile {
    my %args = @_;
    open my $fh, ">base.POSIX.mk" or die "open base.POSIX.mk failed: $!\n";
    my $content = <<EOT;
# GENERATED BY $FindBin::Script: do not hand-edit!!!
#
$license
PROGNAME= charmonize\$(EXEEXT)
CLEANABLE= \$(OBJS) \$(PROGNAME) \$(TEST_OBJS) \$(TESTS) core

TESTS= $args{test_execs}

OBJS= $args{objs}

TEST_OBJS= $args{test_objs}

HEADERS= $args{headers}

all: \$(PROGNAME)

tests: \$(TESTS)

\$(PROGNAME): \$(OBJS)
	\$(LINKER) \$(LINKFLAGS) \$(OBJS) \$(LINKOUT)"\$(PROGNAME)"

\$(OBJS) \$(TEST_OBJS): \$(HEADERS)

$args{test_blocks}

clean:
	rm -f \$(CLEANABLE)
EOT
    print $fh $content;
}

sub gen_makefile_win {
    my %args = @_;
    open my $fh, ">base.win.mk" or die "open base.win.mk failed: $!\n";
    my $content = <<EOT;
# GENERATED BY $FindBin::Script: do not hand-edit!!!
#
$license
PROGNAME= charmonize\$(EXEEXT)
CLEANABLE= \$(OBJS) \$(PROGNAME) \$(TEST_OBJS) \$(TESTS) core *.pdb

TESTS= $args{test_execs}

OBJS= $args{objs}

TEST_OBJS= $args{test_objs}

HEADERS= $args{headers}

all: \$(PROGNAME)

\$(PROGNAME): \$(OBJS)
	\$(LINKER) \$(LINKFLAGS) \$(OBJS) \$(LINKOUT)"\$(PROGNAME)"

\$(OBJS) \$(TEST_OBJS): \$(HEADERS)

tests: \$(TESTS)

$args{test_blocks}

clean:
	CMD /c FOR %i IN (\$(CLEANABLE)) DO IF EXIST %i DEL /F %i
EOT
    print $fh $content;
}


### actual script follows

open my $fh, $0 or die "Can't open $0: $!\n";
scalar <$fh>, scalar <$fh>; # skip first 2 lines
while (<$fh>) {
    /^#/ or last;
    $license .= $_;
}

push @srcs, "charmonize.c";
find \&wanted, "src";

my ($unix_test_blocks, $unix_tests) = unix_tests @tests;
gen_makefile
    test_execs  => join(" ", sort @$unix_tests),
    objs        => join(" ", sort +unix_obj @srcs),
    test_objs   => join(" ", sort +unix_obj @tests),
    headers     => join(" ", sort +unix_obj @hdrs),
    test_blocks => join("\n", sort @$unix_test_blocks);

my ($win_test_blocks, $win_tests) = win_tests @tests;
gen_makefile_win
    test_execs  => join(" ", sort @$win_tests),
    objs        => join(" ", sort +win_obj @srcs),
    test_objs   => join(" ", sort +win_obj @tests),
    headers     => join(" ", sort +win_obj @hdrs),
    test_blocks => join("\n", sort @$win_test_blocks);

__END__

=head1 NAME

gen_charmonizer_makefiles.pl

=head1 SYNOPSIS

    gen_charmonizer_makefiles.pl - keeps the Makefiles in sync with the live tree.

=head1 DESCRIPTION

Be sure to run this code from the charmonizer subdirectory (where the
existing Makefiles live).

