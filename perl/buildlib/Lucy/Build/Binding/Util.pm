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
package Lucy::Build::Binding::Util;
use strict;
use warnings;

sub bind_all {
    my $class = shift;
    $class->bind_debug;
    $class->bind_indexfilenames;
    $class->bind_memorypool;
    $class->bind_priorityqueue;
    $class->bind_sortexternal;
    $class->bind_stepper;
    $class->bind_stringhelper;
}

sub bind_debug {
    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy   PACKAGE = Lucy::Util::Debug

#include "Lucy/Util/Debug.h"

void
DEBUG_PRINT(message)
    char *message;
PPCODE:
    LUCY_DEBUG_PRINT("%s", message);

void
DEBUG(message)
    char *message;
PPCODE:
    LUCY_DEBUG("%s", message);

chy_bool_t
DEBUG_ENABLED()
CODE:
    RETVAL = LUCY_DEBUG_ENABLED;
OUTPUT: RETVAL

=for comment

Keep track of any Lucy objects that have been assigned to global Perl
variables.  This is useful when accounting how many objects should have been
destroyed and diagnosing memory leaks.

=cut

void
track_globals(...)
PPCODE:
{
    CHY_UNUSED_VAR(items);
    LUCY_IFDEF_DEBUG(lucy_Debug_num_globals++;);
}

void
set_env_cache(str)
    char *str;
PPCODE:
    lucy_Debug_set_env_cache(str);

void
ASSERT(maybe)
    int maybe;
PPCODE:
    LUCY_ASSERT(maybe, "XS ASSERT binding test");

IV
num_allocated()
CODE:
    RETVAL = lucy_Debug_num_allocated;
OUTPUT: RETVAL

IV
num_freed()
CODE:
    RETVAL = lucy_Debug_num_freed;
OUTPUT: RETVAL

IV
num_globals()
CODE:
    RETVAL = lucy_Debug_num_globals;
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Util::Debug",
        xs_code    => $xs_code,
    );
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_indexfilenames {
    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy   PACKAGE = Lucy::Util::IndexFileNames

uint64_t
extract_gen(name)
    const lucy_CharBuf *name;
CODE:
    RETVAL = lucy_IxFileNames_extract_gen(name);
OUTPUT: RETVAL

SV*
latest_snapshot(folder)
    lucy_Folder *folder;
CODE:
{
    lucy_CharBuf *latest = lucy_IxFileNames_latest_snapshot(folder);
    RETVAL = XSBind_cb_to_sv(latest);
    CFISH_DECREF(latest);
}
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Util::IndexFileNames",
        xs_code    => $xs_code,
    );

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_memorypool {
    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel            => "Lucy",
        class_name        => "Lucy::Util::MemoryPool",
    );
    $binding->bind_constructor;
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_priorityqueue {
    my @bound = qw(
        Less_Than
        Insert
        Pop
        Pop_All
        Peek
        Get_Size
    );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel       => "Lucy",
        class_name   => "Lucy::Util::PriorityQueue",
    );
    $binding->bind_constructor;
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_sortexternal {
    my @bound = qw(
        Flush
        Flip
        Add_Run
        Refill
        Sort_Cache
        Cache_Count
        Clear_Cache
        Set_Mem_Thresh
    );

    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy    PACKAGE = Lucy::Util::SortExternal

IV
_DEFAULT_MEM_THRESHOLD()
CODE:
    RETVAL = LUCY_SORTEX_DEFAULT_MEM_THRESHOLD;
OUTPUT: RETVAL
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel       => "Lucy",
        class_name   => "Lucy::Util::SortExternal",
        xs_code      => $xs_code,
    );
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_stepper {
    my @bound = qw( Read_Record );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel       => "Lucy",
        class_name   => "Lucy::Util::Stepper",
    );
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_stringhelper {
    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy   PACKAGE = Lucy::Util::StringHelper

=for comment 

Turn an SV's UTF8 flag on.  Equivalent to Encode::_utf8_on, but we don't have
to load Encode.

=cut

void
utf8_flag_on(sv)
    SV *sv;
PPCODE:
    SvUTF8_on(sv);

=for comment

Turn an SV's UTF8 flag off.

=cut

void
utf8_flag_off(sv)
    SV *sv;
PPCODE:
    SvUTF8_off(sv);

SV*
to_base36(num)
    uint64_t num;
CODE:
{
    char base36[lucy_StrHelp_MAX_BASE36_BYTES];
    size_t size = lucy_StrHelp_to_base36(num, &base36);
    RETVAL = newSVpvn(base36, size);
}
OUTPUT: RETVAL

IV
from_base36(str)
    char *str;
CODE:
    RETVAL = strtol(str, NULL, 36);
OUTPUT: RETVAL

=for comment

Upgrade a SV to UTF8, converting Latin1 if necessary. Equivalent to
utf::upgrade().

=cut

void
utf8ify(sv)
    SV *sv;
PPCODE:
    sv_utf8_upgrade(sv);

chy_bool_t
utf8_valid(sv)
    SV *sv;
CODE:
{
    STRLEN len;
    char *ptr = SvPV(sv, len);
    RETVAL = lucy_StrHelp_utf8_valid(ptr, len);
}
OUTPUT: RETVAL

=for comment

Concatenate one scalar onto the end of the other, ignoring UTF-8 status of the
second scalar.  This is necessary because $not_utf8 . $utf8 results in a
scalar which has been infected by the UTF-8 flag of the second argument.

=cut

void
cat_bytes(sv, catted)
    SV *sv;
    SV *catted;
PPCODE:
{
    STRLEN len;
    char *ptr = SvPV(catted, len);
    if (SvUTF8(sv)) { CFISH_THROW(LUCY_ERR, "Can't cat_bytes onto a UTF-8 SV"); }
    sv_catpvn(sv, ptr, len);
}
END_XS_CODE

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Util::StringHelper",
        xs_code    => $xs_code,
    );

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

1;
