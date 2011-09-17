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

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCParser.h"
#include "CFCUtil.h"

struct CFCParser {
    CFCBase base;
};

CFCParser*
CFCParser_new(void) {
    CFCParser *self = (CFCParser*)CFCBase_allocate(sizeof(CFCParser),
                                                   "Clownfish::Parser");
    return CFCParser_init(self);
}

CFCParser*
CFCParser_init(CFCParser *self) {
    return self;
}

void
CFCParser_destroy(CFCParser *self) {
    CFCBase_destroy((CFCBase*)self);
}


