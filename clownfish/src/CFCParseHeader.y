%name CFCParseHeader

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

%token_type { CFCBase* }
%token_destructor { CFCBase_decref((CFCBase*)$$); }
%token_prefix CFC_TOKENTYPE_

%extra_argument { CFCParserState *state }

%include {
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "CFC.h"
#ifndef true
  #define true 1
  #define false 0
#endif

static CFCParcel *current_parcel = NULL;

static const char KW_INT8_T[]   = "int8_t";
static const char KW_INT16_T[]  = "int16_t";
static const char KW_INT32_T[]  = "int32_t";
static const char KW_INT64_T[]  = "int64_t";
static const char KW_UINT8_T[]  = "uint8_t";
static const char KW_UINT16_T[] = "uint16_t";
static const char KW_UINT32_T[] = "uint32_t";
static const char KW_UINT64_T[] = "uint64_t";
static const char KW_CHAR[]     = "char";
static const char KW_SHORT[]    = "short";
static const char KW_INT[]      = "int";
static const char KW_LONG[]     = "long";
static const char KW_SIZE_T[]   = "size_t";
static const char KW_BOOL_T[]   = "bool_t";
static const char KW_FLOAT[]    = "float";
static const char KW_DOUBLE[]   = "double";
}

%syntax_error {
    state->errors = true;
    FREEMEM(state->text);
    state->text = NULL;
    state->cap = 0;
}

%parse_accept {
    FREEMEM(state->text);
    state->text = NULL;
    state->cap = 0;
}

result ::= simple_type(A).
{
    state->result = A;
}

simple_type(A) ::= object_type(B).  { A = B; }
simple_type(A) ::= void_type(B).    { A = B; }
simple_type(A) ::= float_type(B).   { A = B; }
simple_type(A) ::= integer_type(B). { A = B; }
simple_type(A) ::= va_list_type(B). { A = B; }
simple_type(A) ::= arbitrary_type(B). { A = B; }

void_type(A) ::= CONST void_type_specifier.
{
    A = (CFCBase*)CFCType_new_void(true);
}

void_type(A) ::= void_type_specifier.
{
    A = (CFCBase*)CFCType_new_void(false);
}

%type float_type_specifier          {const char*}
%type integer_type_specifier        {const char*}
%type object_type_specifier         {char*}
%destructor float_type_specifier        { }
%destructor integer_type_specifier      { }
%destructor object_type_specifier       { FREEMEM($$); }

void_type_specifier ::= VOID.
va_list_specifier         ::= VA_LIST.
integer_type_specifier(A) ::= INT8_T.    { A = KW_INT8_T; }
integer_type_specifier(A) ::= INT16_T.   { A = KW_INT16_T; }
integer_type_specifier(A) ::= INT32_T.   { A = KW_INT32_T; }
integer_type_specifier(A) ::= INT64_T.   { A = KW_INT64_T; }
integer_type_specifier(A) ::= UINT8_T.   { A = KW_UINT8_T; }
integer_type_specifier(A) ::= UINT16_T.  { A = KW_UINT16_T; }
integer_type_specifier(A) ::= UINT32_T.  { A = KW_UINT32_T; }
integer_type_specifier(A) ::= UINT64_T.  { A = KW_UINT64_T; }
integer_type_specifier(A) ::= CHAR.      { A = KW_CHAR; }
integer_type_specifier(A) ::= SHORT.     { A = KW_SHORT; }
integer_type_specifier(A) ::= INT.       { A = KW_INT; }
integer_type_specifier(A) ::= LONG.      { A = KW_LONG; }
integer_type_specifier(A) ::= SIZE_T.    { A = KW_SIZE_T; }
integer_type_specifier(A) ::= BOOL_T.    { A = KW_BOOL_T; }
float_type_specifier(A) ::= FLOAT.   { A = KW_FLOAT; }
float_type_specifier(A) ::= DOUBLE.  { A = KW_DOUBLE; }

integer_type(A) ::= integer_type_specifier(B).
{
    A = (CFCBase*)CFCType_new_integer(0, B);
}

integer_type(A) ::= CONST integer_type_specifier(B).
{
    A = (CFCBase*)CFCType_new_integer(CFCTYPE_CONST, B);
}

float_type(A) ::= float_type_specifier(B).
{
    A = (CFCBase*)CFCType_new_float(0, B);
}

float_type(A) ::= CONST float_type_specifier(B).
{
    A = (CFCBase*)CFCType_new_float(CFCTYPE_CONST, B);
}

va_list_type(A) ::= va_list_specifier.
{
    A = (CFCBase*)CFCType_new_va_list();
}

arbitrary_type(A) ::= ARBITRARY.
{
    A = (CFCBase*)CFCType_new_arbitrary(current_parcel, CFCParser_current_state->text);
}

object_type(A) ::= object_type_specifier(B) ASTERISK.
{
    A = (CFCBase*)CFCType_new_object(0, CFCParser_get_parcel(), B, 1);
}

object_type_specifier(A) ::= OBJECT_TYPE_SPECIFIER.
{
    A = CFCUtil_strdup(CFCParser_current_state->text);
}

