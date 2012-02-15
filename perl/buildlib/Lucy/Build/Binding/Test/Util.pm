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
package Lucy::Build::Binding::Test::Util;
use strict;
use warnings;

sub bind_all {
    my $class = shift;
    $class->bind_bbsortex;
}

sub bind_bbsortex {
    my @hand_rolled = qw(
        Fetch
        Peek
        Feed
    );
    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy    PACKAGE = Lucy::Test::Util::BBSortEx

SV*
fetch(self)
    lucy_BBSortEx *self;
CODE:
{
    void *address = Lucy_BBSortEx_Fetch(self);
    if (address) {
        RETVAL = XSBind_cfish_to_perl(*(lucy_Obj**)address);
        CFISH_DECREF(*(lucy_Obj**)address);
    }
    else {
        RETVAL = newSV(0);
    }
}
OUTPUT: RETVAL

SV*
peek(self)
    lucy_BBSortEx *self;
CODE:
{
    void *address = Lucy_BBSortEx_Peek(self);
    if (address) {
        RETVAL = XSBind_cfish_to_perl(*(lucy_Obj**)address);
    }
    else {
        RETVAL = newSV(0);
    }
}
OUTPUT: RETVAL

void
feed(self, bb)
    lucy_BBSortEx *self;
    lucy_ByteBuf *bb;
CODE:
    CFISH_INCREF(bb);
    Lucy_BBSortEx_Feed(self, &bb);

END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Test::Util::BBSortEx",
    );
    $binding->bind_constructor;
    $binding->exclude_method($_) for @hand_rolled;
    $binding->append_xs($xs_code);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

1;
