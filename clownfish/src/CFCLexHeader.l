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
static void
S_save_yytext() {
    if (yyleng >= CFCParser_current_state->cap) {
        CFCParser_current_state->text
            = REALLOCATE(CFCParser_current_state->text, yyleng + 1);
        CFCParser_current_state->cap = yyleng + 1;
    }
    strncpy(CFCParser_current_state->text, yytext, yyleng);
    CFCParser_current_state->text[yyleng] = '\0';
}
%}

OBJECT_TYPE_SPECIFIER   ([a-z]+[a-z0-9]*_)?[A-Z]+[A-Z0-9]*[a-z]+[A-Za-z0-9]*

%option noyywrap
%option nodefault
%option yylineno

%%
const       { PARSE(CFC_TOKENTYPE_CONST, NULL); }
nullable    { PARSE(CFC_TOKENTYPE_NULLABLE, NULL); } 
incremented { PARSE(CFC_TOKENTYPE_INCREMENTED, NULL); } 
decremented { PARSE(CFC_TOKENTYPE_DECREMENTED, NULL); } 

void       { PARSE(CFC_TOKENTYPE_VOID, NULL); }
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
va_list    { PARSE(CFC_TOKENTYPE_VA_LIST, NULL); }
[A-Za-z0-9_]+_t { 
                S_save_yytext();
                PARSE(CFC_TOKENTYPE_ARBITRARY, NULL); 
           }
{OBJECT_TYPE_SPECIFIER} {
                S_save_yytext();
                PARSE(CFC_TOKENTYPE_OBJECT_TYPE_SPECIFIER, NULL); 
           }
[*]        { PARSE(CFC_TOKENTYPE_ASTERISK, NULL); }

[ \t\r\n]  /* Skip whitespace. */
.          { 
                printf("Bad input character '%s' at line %d\n", yytext, yylineno);
                yyterminate();
           }
<<EOF>>    { yyterminate(); }
%%

