#define C_LUCY_LOCKFREEREGISTRY
#define LUCY_USE_SHORT_NAMES
#define CHY_USE_SHORT_NAMES

#include "Lucy/Object/LockFreeRegistry.h"
#include "Lucy/Object/Err.h"
#include "Lucy/Object/VTable.h"
#include "Lucy/Util/Atomic.h"
#include "Lucy/Util/Memory.h"

typedef struct lucy_LFRegEntry {
    Obj   *key;
    Obj   *value;
    i32_t  hash_code;
    struct lucy_LFRegEntry *volatile next;
} lucy_LFRegEntry;
#define LFRegEntry lucy_LFRegEntry

LockFreeRegistry*
LFReg_new(size_t capacity)
{
    LockFreeRegistry *self 
        = (LockFreeRegistry*)VTable_Make_Obj(LOCKFREEREGISTRY);
    return LFReg_init(self, capacity);
}

LockFreeRegistry*
LFReg_init(LockFreeRegistry *self, size_t capacity)
{
    self->capacity = capacity;
    self->entries  = CALLOCATE(capacity, sizeof(void*));
    return self;
}

bool_t
LFReg_register(LockFreeRegistry *self, Obj *key, Obj *value)
{
    LFRegEntry  *new_entry = NULL;
    i32_t        hash_code = Obj_Hash_Code(key);
    size_t       bucket    = (u32_t)hash_code % self->capacity;
    LFRegEntry  *volatile *entries = (LFRegEntry*volatile*)self->entries;
    LFRegEntry  *volatile *slot    = &(entries[bucket]);

    /* Proceed through the linked list.  Bail out if the key has already been
     * registered. */
    FIND_END_OF_LINKED_LIST:
    while (*slot) {
        LFRegEntry *entry = *slot;
        if (entry->hash_code == hash_code) {
            if (Obj_Equals(key, entry->key)) {
                return false;
            }
        }
        slot = &(entry->next);
    }

    /* We've found an empty slot. Create the new entry. */ 
    if (!new_entry) {
        new_entry = (LFRegEntry*)MALLOCATE(sizeof(LFRegEntry));
        new_entry->hash_code = hash_code;
        new_entry->key       = INCREF(key);
        new_entry->value     = INCREF(value);
        new_entry->next      = NULL;
    }

    /* Attempt to append the new node onto the end of the linked list.
     * However, if another thread filled the slot since we found it (perhaps
     * while we were allocating that new node), the compare-and-swap will
     * fail.  If that happens, we have to go back and find the new end of the
     * linked list, then try again. */
    if (!Atomic_cas_ptr((void*volatile*)slot, NULL, new_entry)) {
        goto FIND_END_OF_LINKED_LIST;
    }

    return true;
}

Obj*
LFReg_fetch(LockFreeRegistry *self, Obj *key)
{
    i32_t        hash_code = Obj_Hash_Code(key);
    size_t       bucket    = (u32_t)hash_code % self->capacity;
    LFRegEntry **entries   = (LFRegEntry**)self->entries;
    LFRegEntry  *entry     = entries[bucket];

    while (entry) {
        if (entry->hash_code == hash_code) {
            if (Obj_Equals(key, entry->key)) {
                return entry->value;
            }
        }
        entry = entry->next;
    }

    return NULL;
}

void
LFReg_destroy(LockFreeRegistry *self)
{
    size_t i;
    LFRegEntry **entries = (LFRegEntry**)self->entries;

    for (i = 0; i < self->capacity; i++) {
        LFRegEntry *entry = entries[i];
        while (entry) {
            LFRegEntry *next_entry = entry->next;
            DECREF(entry->key);
            DECREF(entry->value);
            FREEMEM(entry);
            entry = next_entry;
        }
    }
    FREEMEM(self->entries);

    SUPER_DESTROY(self, LOCKFREEREGISTRY);
}

/* Copyright 2009 The Apache Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
