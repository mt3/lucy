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

use Test::More tests => 57;
use Clownfish::Type;
use Clownfish::Parser;

my $parser = Clownfish::Parser->new;

# Set and leave parcel.
my $parcel = $parser->parcel_definition('parcel Neato;')
    or die "failed to process parcel_definition";

for my $bad_specifier (qw( foo fooBar Foo_Bar FOOBAR 1Foo 1FOO )) {
    ok( !$parser->object_type_specifier($bad_specifier),
        "reject bad object_type_specifier $bad_specifier"
    );
    eval {
        my $type = Clownfish::Type->new_object(
            parcel    => 'Neato',
            specifier => $bad_specifier,
        );
    };
    like( $@, qr/specifier/,
        "constructor rejects bad specifier $bad_specifier" );
}

for my $specifier (qw( Foo FooJr FooIII Foo4th )) {
    is( $parser->object_type_specifier($specifier),
        $specifier, "object_type_specifier: $specifier" );
    is( $parser->object_type_specifier("neato_$specifier"),
        "neato_$specifier", "object_type_specifier: neato_$specifier" );
    my $type = $parser->parse("$specifier*");
    ok( $type && $type->is_object, "$specifier*" );
    $type = $parser->parse("neato_$specifier*");
    ok( $type && $type->is_object, "neato_$specifier*" );
    $type = $parser->parse("const $specifier*");
    ok( $type && $type->is_object, "const $specifier*" );
    $type = $parser->parse("incremented $specifier*");
    ok( $type && $type->is_object, "incremented $specifier*" );
    $type = $parser->parse("decremented $specifier*");
    ok( $type && $type->is_object, "decremented $specifier*" );
}

eval { my $type = Clownfish::Type->new_object };
like( $@, qr/specifier/i, "specifier required" );

for ( 0, 2 ) {
    eval {
        my $type = Clownfish::Type->new_object(
            specifier   => 'Foo',
            indirection => $_,
        );
    };
    like( $@, qr/indirection/i, "invalid indirection of $_" );
}

my $foo_type    = Clownfish::Type->new_object( specifier => 'Foo' );
my $another_foo = Clownfish::Type->new_object( specifier => 'Foo' );
ok( $foo_type->equals($another_foo), "equals" );

my $bar_type = Clownfish::Type->new_object( specifier => 'Bar' );
ok( !$foo_type->equals($bar_type), "different specifier spoils equals" );

my $foreign_foo = Clownfish::Type->new_object(
    specifier => 'Foo',
    parcel    => 'Foreign',
);
ok( !$foo_type->equals($foreign_foo), "different parcel spoils equals" );
is( $foreign_foo->get_specifier, "foreign_Foo",
    "prepend parcel prefix to specifier" );

my $incremented_foo = Clownfish::Type->new_object(
    specifier   => 'Foo',
    incremented => 1,
);
ok( $incremented_foo->incremented, "incremented" );
ok( !$foo_type->incremented,       "not incremented" );
ok( !$foo_type->equals($incremented_foo),
    "different incremented spoils equals"
);

my $decremented_foo = Clownfish::Type->new_object(
    specifier   => 'Foo',
    decremented => 1,
);
ok( $decremented_foo->decremented, "decremented" );
ok( !$foo_type->decremented,       "not decremented" );
ok( !$foo_type->equals($decremented_foo),
    "different decremented spoils equals"
);

my $const_foo = Clownfish::Type->new_object(
    specifier => 'Foo',
    const     => 1,
);
ok( !$foo_type->equals($const_foo), "different const spoils equals" );
like( $const_foo->to_c, qr/const/, "const included in C representation" );

my $string_type = Clownfish::Type->new_object( specifier => 'CharBuf', );
ok( !$foo_type->is_string_type,   "Not is_string_type" );
ok( $string_type->is_string_type, "is_string_type" );

