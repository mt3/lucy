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

#include "ruby.h"
#include "CFC.h"

static VALUE mBinding;
static VALUE mClownfish;
static VALUE mCFC;
static VALUE cBindCore;
static VALUE cHierarchy;

static VALUE S_CFC_Binding_Core_Alloc(VALUE klass) {
    void *ptr = NULL;
    return Data_Wrap_Struct(klass, NULL, NULL, ptr);
}

static VALUE S_CFC_Binding_Core_Init(VALUE self_rb, VALUE hierarchy, VALUE dest, VALUE header, VALUE footer) {
    CFCHierarchy* hierarchy_obj;
    CFCBindCore* self;

    Data_Get_Struct(hierarchy,CFCHierarchy,hierarchy_obj);
    Data_Get_Struct(self_rb, CFCBindCore, self);

    self = CFCBindCore_new(hierarchy_obj,StringValuePtr(dest), StringValuePtr(header), StringValuePtr(footer));

    DATA_PTR(self_rb) = self;
    return self_rb;
}

static VALUE S_CFC_Binding_Core_Write_All_Modified(int argc, VALUE *argv, VALUE self_rb) {
    CFCBindCore *self;

    int modified = argc > 0 && RTEST(argv[0]) ? 1 : 0;

    Data_Get_Struct(self_rb, CFCBindCore, self);
    CFCBindCore_write_all_modified(self,modified);

    return Qnil;
}

static VALUE S_CFC_Hierarchy_Alloc(VALUE klass) {
    void *ptr = NULL;
    return Data_Wrap_Struct(klass, NULL, NULL, ptr);
}

static VALUE S_CFC_Hierarchy_Init(VALUE self_rb, VALUE source, VALUE dest) {
    CFCHierarchy* self;

    Data_Get_Struct(self_rb,CFCHierarchy, self);

    self = CFCHierarchy_new(StringValuePtr(source), StringValuePtr(dest));

    DATA_PTR(self_rb) = self;
    return self_rb;
}

static VALUE S_CFC_Hierarchy_Build(VALUE self_rb) {
    CFCHierarchy *self;

    Data_Get_Struct(self_rb, CFCHierarchy, self);
    CFCHierarchy_build(self);

    return Qnil;
}

void Init_CFC() { 
    mClownfish  = rb_define_module("Clownfish");
    mCFC        = rb_define_module_under(mClownfish, "CFC");
    mBinding    = rb_define_module_under(mCFC, "Binding");
    cHierarchy  = rb_define_class_under(mCFC, "Hierarchy", rb_cObject);
    cBindCore   = rb_define_class_under(mBinding, "Core", rb_cObject);

    rb_define_alloc_func(cHierarchy, S_CFC_Hierarchy_Alloc);
    rb_define_method(cHierarchy, "initialize", S_CFC_Hierarchy_Init, 2);
    rb_define_method(cHierarchy, "build", S_CFC_Hierarchy_Build, 0);

    rb_define_alloc_func(cBindCore, S_CFC_Binding_Core_Alloc);
    rb_define_method(cBindCore, "initialize", S_CFC_Binding_Core_Init, 4);
    rb_define_method(cBindCore, "write_all_modified", S_CFC_Binding_Core_Write_All_Modified, -1);
}

