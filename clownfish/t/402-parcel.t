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

use Test::More tests => 7;

BEGIN { use_ok('Clownfish::Parcel') }

package ClownfishyThing;
use base qw( Clownfish::Symbol );

sub new {
    return shift->SUPER::new( micro_sym => 'sym', exposure => 'parcel', @_ );
}

package main;

# Register singleton.
Clownfish::Parcel->singleton( name => 'Crustacean', cnick => 'Crust', );

my $thing = ClownfishyThing->new;
is( $thing->get_prefix, '', 'get_prefix with no parcel' );
is( $thing->get_Prefix, '', 'get_Prefix with no parcel' );
is( $thing->get_PREFIX, '', 'get_PREFIx with no parcel' );

$thing = ClownfishyThing->new( parcel => 'Crustacean' );
is( $thing->get_prefix, 'crust_', 'get_prefix with parcel' );
is( $thing->get_Prefix, 'Crust_', 'get_Prefix with parcel' );
is( $thing->get_PREFIX, 'CRUST_', 'get_PREFIx with parcel' );

