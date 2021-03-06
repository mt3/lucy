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

#define C_LUCY_DATAREADER
#include "Lucy/Util/ToolSet.h"

#include "Lucy/Index/DataReader.h"
#include "Lucy/Index/Segment.h"
#include "Lucy/Index/Snapshot.h"
#include "Lucy/Plan/Schema.h"
#include "Lucy/Store/Folder.h"

DataReader*
DataReader_init(DataReader *self, Schema *schema, Folder *folder,
                Snapshot *snapshot, VArray *segments, int32_t seg_tick) {
    self->schema   = (Schema*)INCREF(schema);
    self->folder   = (Folder*)INCREF(folder);
    self->snapshot = (Snapshot*)INCREF(snapshot);
    self->segments = (VArray*)INCREF(segments);
    self->seg_tick = seg_tick;
    if (seg_tick != -1) {
        if (!segments) {
            THROW(ERR, "No segments array provided, but seg_tick is %i32",
                  seg_tick);
        }
        else {
            Segment *segment = (Segment*)VA_Fetch(segments, seg_tick);
            if (!segment) {
                THROW(ERR, "No segment at seg_tick %i32", seg_tick);
            }
            self->segment = (Segment*)INCREF(segment);
        }
    }
    else {
        self->segment = NULL;
    }

    ABSTRACT_CLASS_CHECK(self, DATAREADER);
    return self;
}

void
DataReader_destroy(DataReader *self) {
    DECREF(self->schema);
    DECREF(self->folder);
    DECREF(self->snapshot);
    DECREF(self->segments);
    DECREF(self->segment);
    SUPER_DESTROY(self, DATAREADER);
}

Schema*
DataReader_get_schema(DataReader *self) {
    return self->schema;
}

Folder*
DataReader_get_folder(DataReader *self) {
    return self->folder;
}

Snapshot*
DataReader_get_snapshot(DataReader *self) {
    return self->snapshot;
}

VArray*
DataReader_get_segments(DataReader *self) {
    return self->segments;
}

int32_t
DataReader_get_seg_tick(DataReader *self) {
    return self->seg_tick;
}

Segment*
DataReader_get_segment(DataReader *self) {
    return self->segment;
}


