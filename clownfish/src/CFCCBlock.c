/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdlib.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "CFCCBlock.h"

struct CFCCBlock {
    const char *contents;
};

CFCCBlock*
CFCCBlock_new(const char *contents)
{
    CFCCBlock *self = (CFCCBlock*)malloc(sizeof(CFCCBlock));
    if (!self) { croak("malloc failed"); }
    return CFCCBlock_init(self, contents);
}

CFCCBlock*
CFCCBlock_init(CFCCBlock *self, const char *contents) 
{
    self->contents = savepv(contents);
    return self;
}

void
CFCCBlock_destroy(CFCCBlock *self)
{
    Safefree(self->contents);
    free(self);
}


const char*
CFCCBlock_get_contents(CFCCBlock *self)
{
    return self->contents;
}

