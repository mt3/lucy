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
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <ctype.h>

#ifndef true
    #define true 1
    #define false 0
#endif

#define CFC_NEED_BASE_STRUCT_DEF
#include "CFCBase.h"
#include "CFCHierarchy.h"
#include "CFCClass.h"
#include "CFCFile.h"
#include "CFCSymbol.h"
#include "CFCUtil.h"
#include "CFCParser.h"

struct CFCHierarchy {
    CFCBase base;
    char *source;
    char *dest;
    CFCParser *parser;
    CFCClass **trees;
    size_t num_trees;
    CFCFile **files;
    size_t num_files;
};

static void
S_parse_cf_files(CFCHierarchy *self);

static void
S_add_file(CFCHierarchy *self, CFCFile *file);

static void
S_add_tree(CFCHierarchy *self, CFCClass *klass);

static CFCFile*
S_fetch_file(CFCHierarchy *self, const char *source_class);

// Recursive helper function for CFCUtil_propagate_modified.
static int
S_do_propagate_modified(CFCHierarchy *self, CFCClass *klass, int modified);

const static CFCMeta CFCHIERARCHY_META = {
    "Clownfish::Hierarchy",
    sizeof(CFCHierarchy),
    (CFCBase_destroy_t)CFCHierarchy_destroy
};

CFCHierarchy*
CFCHierarchy_new(const char *source, const char *dest) {
    CFCHierarchy *self = (CFCHierarchy*)CFCBase_allocate(&CFCHIERARCHY_META);
    return CFCHierarchy_init(self, source, dest);
}

CFCHierarchy*
CFCHierarchy_init(CFCHierarchy *self, const char *source, const char *dest) {
    if (!source || !strlen(source) || !dest || !strlen(dest)) {
        CFCUtil_die("Both 'source' and 'dest' are required");
    }
    self->source    = CFCUtil_strdup(source);
    self->dest      = CFCUtil_strdup(dest);
    self->trees     = (CFCClass**)CALLOCATE(1, sizeof(CFCClass*));
    self->num_trees = 0;
    self->files     = (CFCFile**)CALLOCATE(1, sizeof(CFCFile*));
    self->num_files = 0;
    self->parser    = CFCParser_new();
    return self;
}

void
CFCHierarchy_destroy(CFCHierarchy *self) {
    size_t i;
    for (i = 0; self->trees[i] != NULL; i++) {
        CFCBase_decref((CFCBase*)self->trees[i]);
    }
    for (i = 0; self->files[i] != NULL; i++) {
        CFCBase_decref((CFCBase*)self->files[i]);
    }
    FREEMEM(self->trees);
    FREEMEM(self->files);
    FREEMEM(self->source);
    FREEMEM(self->dest);
    CFCBase_decref((CFCBase*)self->parser);
    CFCBase_destroy((CFCBase*)self);
}

void
CFCHierarchy_build(CFCHierarchy *self) {
    S_parse_cf_files(self);
    size_t i;
    for (i = 0; self->trees[i] != NULL; i++) {
        CFCClass_grow_tree(self->trees[i]);
    }
}

static char**
S_find_cfh(char *dir, char **cfh_list, size_t num_cfh) {
    void *dirhandle = CFCUtil_opendir(dir);
    size_t full_path_cap = strlen(dir) * 2;
    char *full_path = (char*)MALLOCATE(full_path_cap);
    const char *entry = NULL;
    while (NULL != (entry = CFCUtil_dirnext(dirhandle))) {
        // Ignore updirs and hidden files.
        if (strncmp(entry, ".", 1) == 0) {
            continue;
        }

        size_t name_len = strlen(entry);
        size_t needed = strlen(dir) + 1 + name_len + 1;
        if (needed > full_path_cap) {
            full_path_cap = needed;
            full_path = (char*)MALLOCATE(full_path_cap);
        }
        int full_path_len = sprintf(full_path, "%s" CFCUTIL_PATH_SEP "%s",
                                    dir, entry);
        const char *cfh_suffix = strstr(full_path, ".cfh");

        if (cfh_suffix == full_path + (full_path_len - 4)) {
            cfh_list = (char**)REALLOCATE(cfh_list,
                                          (num_cfh + 2) * sizeof(char*));
            cfh_list[num_cfh++] = CFCUtil_strdup(full_path);
            cfh_list[num_cfh] = NULL;
        }
        else if (CFCUtil_is_dir(full_path)) {
            cfh_list = S_find_cfh(full_path, cfh_list, num_cfh);
            num_cfh = 0;
            if (cfh_list) {
                while (cfh_list[num_cfh] != NULL) { num_cfh++; }
            }
        }
    }

    FREEMEM(full_path);
    CFCUtil_closedir(dirhandle, dir);
    return cfh_list;
}

static void
S_parse_cf_files(CFCHierarchy *self) {
    char **all_source_paths = (char**)CALLOCATE(1, sizeof(char*));
    all_source_paths = S_find_cfh(self->source, all_source_paths, 0);
    const char *source_dir = self->source;
    size_t source_dir_len  = strlen(source_dir);
    size_t all_classes_cap = 10;
    size_t num_classes     = 0;
    CFCClass **all_classes = (CFCClass**)MALLOCATE(
                                 (all_classes_cap + 1) * sizeof(CFCClass*));
    char *source_class = NULL;
    size_t source_class_max = 0;

    // Process any file that has at least one class declaration.
    int i;
    for (i = 0; all_source_paths[i] != NULL; i++) {
        // Derive the name of the class that owns the module file.
        char *source_path = all_source_paths[i];
        size_t source_path_len = strlen(source_path);
        if (strncmp(source_path, source_dir, source_dir_len) != 0) {
            CFCUtil_die("'%s' doesn't start with '%s'", source_path,
                        source_dir);
        }
        size_t j;
        size_t source_class_len = 0;
        if (source_class_max < source_path_len * 2 + 1) {
            source_class_max = source_path_len * 2 + 1;
            source_class = (char*)REALLOCATE(source_class, source_class_max);
        }
        for (j = source_dir_len; j < source_path_len - strlen(".cfh"); j++) {
            char c = source_path[j];
            if (isalnum(c)) {
                source_class[source_class_len++] = c;
            }
            else {
                if (source_class_len != 0) {
                    source_class[source_class_len++] = ':';
                    source_class[source_class_len++] = ':';
                }
            }
        }
        source_class[source_class_len] = '\0';

        // Slurp, parse, add parsed file to pool.
        size_t unused;
        char *content = CFCUtil_slurp_text(source_path, &unused);
        CFCFile *file = CFCParser_parse_file(self->parser, content, source_class);
        if (!file) {
            CFCUtil_die("parser error for %s", source_path);
        }
        S_add_file(self, file);

        CFCClass **classes_in_file = CFCFile_classes(file);
        for (j = 0; classes_in_file[j] != NULL; j++) {
            if (num_classes == all_classes_cap) {
                all_classes_cap += 10;
                all_classes = (CFCClass**)REALLOCATE(
                                  all_classes,
                                  (all_classes_cap + 1) * sizeof(CFCClass*));
            }
            all_classes[num_classes++] = classes_in_file[j];
        }
    }
    all_classes[num_classes] = NULL;

    // Wrangle the classes into hierarchies and figure out inheritance.
    for (i = 0; all_classes[i] != NULL; i++) {
        CFCClass *klass = all_classes[i];
        const char *parent_name = CFCClass_get_parent_class_name(klass);
        if (parent_name) {
            size_t j;
            for (j = 0; ; j++) {
                CFCClass *maybe_parent = all_classes[j];
                if (!maybe_parent) {
                    CFCUtil_die("Parent class '%s' not defined", parent_name);
                }
                const char *maybe_parent_name
                    = CFCClass_get_class_name(maybe_parent);
                if (strcmp(parent_name, maybe_parent_name) == 0) {
                    CFCClass_add_child(maybe_parent, klass);
                    break;
                }
            }
        }
        else {
            S_add_tree(self, klass);
        }
    }

    FREEMEM(all_classes);
    for (i = 0; all_source_paths[i] != NULL; i++) {
        FREEMEM(all_source_paths[i]);
    }
    FREEMEM(all_source_paths);
    FREEMEM(source_class);
}

int
CFCHierarchy_propagate_modified(CFCHierarchy *self, int modified) {
    // Seed the recursive write.
    int somebody_is_modified = false;
    size_t i;
    for (i = 0; self->trees[i] != NULL; i++) {
        CFCClass *tree = self->trees[i];
        if (S_do_propagate_modified(self, tree, modified)) {
            somebody_is_modified = true;
        }
    }
    if (somebody_is_modified || modified) {
        return true;
    }
    else {
        return false;
    }
}

int
S_do_propagate_modified(CFCHierarchy *self, CFCClass *klass, int modified) {
    const char *source_class = CFCClass_get_source_class(klass);
    CFCFile *file = S_fetch_file(self, source_class);
    size_t cfh_buf_size = CFCFile_path_buf_size(file, self->source);
    char *source_path = (char*)MALLOCATE(cfh_buf_size);
    CFCFile_cfh_path(file, source_path, cfh_buf_size, self->source);
    size_t h_buf_size = CFCFile_path_buf_size(file, self->dest);
    char *h_path = (char*)MALLOCATE(h_buf_size);
    CFCFile_h_path(file, h_path, h_buf_size, self->dest);

    if (!CFCUtil_current(source_path, h_path)) {
        modified = true;
    }
    if (modified) {
        CFCFile_set_modified(file, modified);
    }

    // Proceed to the next generation.
    int somebody_is_modified = modified;
    size_t i;
    CFCClass **children = CFCClass_children(klass);
    for (i = 0; children[i] != NULL; i++) {
        CFCClass *kid = children[i];
        if (CFCClass_final(klass)) {
            CFCUtil_die("Attempt to inherit from final class '%s' by '%s'",
                        CFCClass_get_class_name(klass),
                        CFCClass_get_class_name(kid));
        }
        if (S_do_propagate_modified(self, kid, modified)) {
            somebody_is_modified = 1;
        }
    }

    return somebody_is_modified;
}

static void
S_add_tree(CFCHierarchy *self, CFCClass *klass) {
    CFCUTIL_NULL_CHECK(klass);
    const char *full_struct_sym = CFCClass_full_struct_sym(klass);
    size_t i;
    for (i = 0; self->trees[i] != NULL; i++) {
        const char *existing = CFCClass_full_struct_sym(self->trees[i]);
        if (strcmp(full_struct_sym, existing) == 0) {
            CFCUtil_die("Tree '%s' alread added", full_struct_sym);
        }
    }
    self->num_trees++;
    size_t size = (self->num_trees + 1) * sizeof(CFCClass*);
    self->trees = (CFCClass**)REALLOCATE(self->trees, size);
    self->trees[self->num_trees - 1]
        = (CFCClass*)CFCBase_incref((CFCBase*)klass);
    self->trees[self->num_trees] = NULL;
}

CFCClass**
CFCHierarchy_ordered_classes(CFCHierarchy *self) {
    size_t num_classes = 0;
    size_t max_classes = 10;
    CFCClass **ladder = (CFCClass**)MALLOCATE(
                            (max_classes + 1) * sizeof(CFCClass*));
    size_t i;
    for (i = 0; self->trees[i] != NULL; i++) {
        CFCClass *tree = self->trees[i];
        CFCClass **child_ladder = CFCClass_tree_to_ladder(tree);
        size_t j;
        for (j = 0; child_ladder[j] != NULL; j++) {
            if (num_classes == max_classes) {
                max_classes += 10;
                ladder = (CFCClass**)REALLOCATE(
                             ladder, (max_classes + 1) * sizeof(CFCClass*));
            }
            ladder[num_classes++] = child_ladder[j];
        }
        FREEMEM(child_ladder);
    }
    ladder[num_classes] = NULL;
    return ladder;
}

static CFCFile*
S_fetch_file(CFCHierarchy *self, const char *source_class) {
    size_t i;
    for (i = 0; self->files[i] != NULL; i++) {
        const char *existing = CFCFile_get_source_class(self->files[i]);
        if (strcmp(source_class, existing) == 0) {
            return self->files[i];
        }
    }
    return NULL;
}

static void
S_add_file(CFCHierarchy *self, CFCFile *file) {
    CFCUTIL_NULL_CHECK(file);
    const char *source_class = CFCFile_get_source_class(file);
    CFCClass **classes = CFCFile_classes(file);
    size_t i;
    for (i = 0; self->files[i] != NULL; i++) {
        CFCFile *existing = self->files[i];
        const char *old_source_class = CFCFile_get_source_class(existing);
        if (strcmp(source_class, old_source_class) == 0) {
            CFCUtil_die("File for source class %s already registered",
                        source_class);
        }
        CFCClass **existing_classes = CFCFile_classes(existing);
        size_t j;
        for (j = 0; classes[j] != NULL; j++) {
            const char *new_class_name = CFCClass_get_class_name(classes[j]);
            size_t k;
            for (k = 0; existing_classes[k] != NULL; k++) {
                const char *existing_class_name
                    = CFCClass_get_class_name(existing_classes[k]);
                if (strcmp(new_class_name, existing_class_name) == 0) {
                    CFCUtil_die("Class '%s' already registered",
                                new_class_name);
                }
            }
        }
    }
    self->num_files++;
    size_t size = (self->num_files + 1) * sizeof(CFCFile*);
    self->files = (CFCFile**)REALLOCATE(self->files, size);
    self->files[self->num_files - 1]
        = (CFCFile*)CFCBase_incref((CFCBase*)file);
    self->files[self->num_files] = NULL;
}

struct CFCFile**
CFCHierarchy_files(CFCHierarchy *self) {
    return self->files;
}

const char*
CFCHierarchy_get_source(CFCHierarchy *self) {
    return self->source;
}

const char*
CFCHierarchy_get_dest(CFCHierarchy *self) {
    return self->dest;
}


