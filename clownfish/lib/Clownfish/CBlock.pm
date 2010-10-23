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

package Clownfish::CBlock;
use Clownfish::Util qw( verify_args );
use Carp;

our %new_PARAMS = ( contents => undef, );

sub new {
    my $either = shift;
    verify_args( \%new_PARAMS, @_ ) or confess $@;
    my $self = bless { %new_PARAMS, @_ }, ref($either) || $either;
    confess("Missing required param 'contents'")
        unless defined $self->{contents};
    return $self;
}

# Accessors.
sub get_contents { shift->{contents} }

1;

__END__

__POD__

=head1 NAME

Clownfish::CBlock - A block of embedded C code.

=head1 DESCRIPTION

CBlock exists to support embedding literal C code within Clownfish header
files:

    class Crustacean::Lobster {
        /* ... */

        /** Give a lobstery greeting.
         */
        inert inline void
        say_hello(Lobster *self);
    }

    __C__
    #include <stdio.h>
    static CHY_INLINE void
    crust_Lobster_say_hello(crust_Lobster *self)
    {
        printf("Prepare to die, human scum.\n");
    }
    __END_C__

=head1 METHODS

=head2 new

    my $c_block = Clownfish::CBlock->new(
        contents => $text,
    );

=over

=item * B<contents> - Raw C code.

=back

=head2 get_contents

Accessor.

=cut

