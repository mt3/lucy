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

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCMemPool.h"
#include "CFCUtil.h"

struct CFCMemPool {
    CFCBase base;
    size_t size;
    size_t consumed;
    char *arena;
};

CFCMemPool*
CFCMemPool_new(size_t size) {
    CFCMemPool *self = (CFCMemPool*)CFCBase_allocate(sizeof(CFCMemPool),
                                                     "Clownfish::MemPool");
    return CFCMemPool_init(self, size);
}

CFCMemPool*
CFCMemPool_init(CFCMemPool *self, size_t size) {
    size = size ? size : 0x100000;
    self->arena    = MALLOCATE(size);
    self->size     = size;
    self->consumed = 0;
    return self;
}

void*
CFCMemPool_allocate(CFCMemPool *self, size_t size) {
    size_t overage = (8 - (size % 8)) % 8;
    size_t amount = size + overage;
    if (self->consumed + amount > self->size) {
        CFCUtil_die("Exceeded max size of memory pool");
    }
    void *result = self->arena + self->consumed;
    self->consumed += amount;
    return result;
}

void
CFCMemPool_destroy(CFCMemPool *self) {
    FREEMEM(self->arena);
    CFCBase_destroy((CFCBase*)self);
}

