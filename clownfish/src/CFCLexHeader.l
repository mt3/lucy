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

%{
#include "CFC.h"
#include "CFCParseHeader.h"
void
CFCParseHeader(void *header_parser, int token_type, CFCBase *value,
               CFCParserState *state);
#define PARSE(token_type, value) \
    CFCParseHeader(CFCParser_current_parser, token_type, value, \
        CFCParser_current_state)
%}

%option noyywrap

%%
void       { PARSE(CFC_TOKENTYPE_VOID, NULL); }
const      { PARSE(CFC_TOKENTYPE_CONST, NULL); }
float      { PARSE(CFC_TOKENTYPE_FLOAT, NULL); }
double     { PARSE(CFC_TOKENTYPE_DOUBLE, NULL); }
int8_t     { PARSE(CFC_TOKENTYPE_INT8_T, NULL); }
int16_t    { PARSE(CFC_TOKENTYPE_INT16_T, NULL); }
int32_t    { PARSE(CFC_TOKENTYPE_INT32_T, NULL); }
int64_t    { PARSE(CFC_TOKENTYPE_INT64_T, NULL); }
uint8_t    { PARSE(CFC_TOKENTYPE_UINT8_T, NULL); }
uint16_t   { PARSE(CFC_TOKENTYPE_UINT16_T, NULL); }
uint32_t   { PARSE(CFC_TOKENTYPE_UINT32_T, NULL); }
uint64_t   { PARSE(CFC_TOKENTYPE_UINT64_T, NULL); }
char       { PARSE(CFC_TOKENTYPE_CHAR, NULL); }
short      { PARSE(CFC_TOKENTYPE_SHORT, NULL); }
int        { PARSE(CFC_TOKENTYPE_INT, NULL); }
long       { PARSE(CFC_TOKENTYPE_LONG, NULL); }
size_t     { PARSE(CFC_TOKENTYPE_SIZE_T, NULL); }
bool_t     { PARSE(CFC_TOKENTYPE_BOOL_T, NULL); }
%%

