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

package KinoSearch::Object::VArray;
use KinoSearch;

1;

__END__

__BINDING__

my $xs_code = <<'END_XS_CODE';
MODULE = KinoSearch   PACKAGE = KinoSearch::Object::VArray

SV*
shallow_copy(self)
    kino_VArray *self;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(Kino_VA_Shallow_Copy(self));
OUTPUT: RETVAL

SV*
_deserialize(either_sv, instream)
    SV *either_sv;
    kino_InStream *instream;
CODE:
    CHY_UNUSED_VAR(either_sv);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(kino_VA_deserialize(NULL, instream));
OUTPUT: RETVAL

SV*
_clone(self)
    kino_VArray *self;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(Kino_VA_Clone(self));
OUTPUT: RETVAL

SV*
shift(self)
    kino_VArray *self;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(Kino_VA_Shift(self));
OUTPUT: RETVAL

SV*
pop(self)
    kino_VArray *self;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(Kino_VA_Pop(self));
OUTPUT: RETVAL

SV*
delete(self, tick)
    kino_VArray *self;
    uint32_t    tick;
CODE:
    RETVAL = CFISH_OBJ_TO_SV_NOINC(Kino_VA_Delete(self, tick));
OUTPUT: RETVAL

void
store(self, tick, value);
    kino_VArray *self; 
    uint32_t     tick;
    kino_Obj    *value;
PPCODE:
{
    if (value) { LUCY_INCREF(value); }
    kino_VA_store(self, tick, value);
}

SV*
fetch(self, tick)
    kino_VArray *self;
    uint32_t     tick;
CODE:
    RETVAL = CFISH_OBJ_TO_SV(Kino_VA_Fetch(self, tick));
OUTPUT: RETVAL
END_XS_CODE

Clownfish::Binding::Perl::Class->register(
    parcel       => "KinoSearch",
    class_name   => "KinoSearch::Object::VArray",
    xs_code      => $xs_code,
    bind_methods => [
        qw(
            Push
            Push_VArray
            Unshift
            Excise
            Resize
            Get_Size
            )
    ],
    bind_constructors => ["new"],
);


