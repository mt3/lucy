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
    CFCParseHeader(void *header_parser, int token_type, char *value,
                   CFCParser *state);
    /* Invoke Lemon-generated parser. */
    #define PARSE(token_type) \
        CFCParseHeader(CFCParser_current_parser, token_type, NULL, \
            CFCParser_current_state)

    /* Dupe yytext and invoke parser. */
    #define SAVE_AND_PARSE(token_type) \
        CFCParseHeader(CFCParser_current_parser, token_type, \
			CFCParser_dupe(CFCParser_current_state, yytext), \
			CFCParser_current_state)
%}

CLASS_NAME_COMPONENT    [A-Z]+[A-Z0-9]*[a-z]+[A-Za-z0-9]*

%option noyywrap
%option nodefault
%option yylineno

%x CBLOCK

%%
const       { PARSE(CFC_TOKENTYPE_CONST); }
nullable    { PARSE(CFC_TOKENTYPE_NULLABLE); } 
incremented { PARSE(CFC_TOKENTYPE_INCREMENTED); } 
decremented { PARSE(CFC_TOKENTYPE_DECREMENTED); } 

void       { PARSE(CFC_TOKENTYPE_VOID); }
float      { PARSE(CFC_TOKENTYPE_FLOAT); }
double     { PARSE(CFC_TOKENTYPE_DOUBLE); }
int8_t     { PARSE(CFC_TOKENTYPE_INT8_T); }
int16_t    { PARSE(CFC_TOKENTYPE_INT16_T); }
int32_t    { PARSE(CFC_TOKENTYPE_INT32_T); }
int64_t    { PARSE(CFC_TOKENTYPE_INT64_T); }
uint8_t    { PARSE(CFC_TOKENTYPE_UINT8_T); }
uint16_t   { PARSE(CFC_TOKENTYPE_UINT16_T); }
uint32_t   { PARSE(CFC_TOKENTYPE_UINT32_T); }
uint64_t   { PARSE(CFC_TOKENTYPE_UINT64_T); }
char       { PARSE(CFC_TOKENTYPE_CHAR); }
short      { PARSE(CFC_TOKENTYPE_SHORT); }
int        { PARSE(CFC_TOKENTYPE_INT); }
long       { PARSE(CFC_TOKENTYPE_LONG); }
size_t     { PARSE(CFC_TOKENTYPE_SIZE_T); }
bool_t     { PARSE(CFC_TOKENTYPE_BOOL_T); }
va_list    { PARSE(CFC_TOKENTYPE_VA_LIST); }
true       { PARSE(CFC_TOKENTYPE_TRUE); }
false      { PARSE(CFC_TOKENTYPE_FALSE); }
NULL       { PARSE(CFC_TOKENTYPE_NULL); }
cnick      { PARSE(CFC_TOKENTYPE_CNICK); }
inherits   { PARSE(CFC_TOKENTYPE_INHERITS); }
parcel     { PARSE(CFC_TOKENTYPE_PARCEL); }
class      { PARSE(CFC_TOKENTYPE_CLASS); }
public     { PARSE(CFC_TOKENTYPE_PUBLIC); }
private    { PARSE(CFC_TOKENTYPE_PRIVATE); }
local      { PARSE(CFC_TOKENTYPE_LOCAL); }
inert      { PARSE(CFC_TOKENTYPE_INERT); }
inline     { PARSE(CFC_TOKENTYPE_INLINE); }
abstract   { PARSE(CFC_TOKENTYPE_ABSTRACT); }
final      { PARSE(CFC_TOKENTYPE_FINAL); }

::         { PARSE(CFC_TOKENTYPE_SCOPE_OP); }
[*]        { PARSE(CFC_TOKENTYPE_ASTERISK); }
\{         { PARSE(CFC_TOKENTYPE_LEFT_CURLY_BRACE); }
\}         { PARSE(CFC_TOKENTYPE_RIGHT_CURLY_BRACE); }
[\[]       { PARSE(CFC_TOKENTYPE_LEFT_SQUARE_BRACKET); }
[\]]       { PARSE(CFC_TOKENTYPE_RIGHT_SQUARE_BRACKET); }
[\(]       { PARSE(CFC_TOKENTYPE_LEFT_PAREN); }
[\)]       { PARSE(CFC_TOKENTYPE_RIGHT_PAREN); }
\.\.\.     { PARSE(CFC_TOKENTYPE_ELLIPSIS); }
,          { PARSE(CFC_TOKENTYPE_COMMA); }
;          { PARSE(CFC_TOKENTYPE_SEMICOLON); }
:          { PARSE(CFC_TOKENTYPE_COLON); }
=          { PARSE(CFC_TOKENTYPE_EQUALS); }

-?0x[0-9A-Fa-f]+       { SAVE_AND_PARSE(CFC_TOKENTYPE_HEX_LITERAL); }
-?[0-9]+               { SAVE_AND_PARSE(CFC_TOKENTYPE_INTEGER_LITERAL); }
-?[ ]*[0-9+].[0-9]+    { SAVE_AND_PARSE(CFC_TOKENTYPE_FLOAT_LITERAL); }
\"([^\"\\]|\\.)*\"     { SAVE_AND_PARSE(CFC_TOKENTYPE_STRING_LITERAL); }

[a-zA-Z_][a-zA-Z0-9_]* { SAVE_AND_PARSE(CFC_TOKENTYPE_IDENTIFIER); }

__C__[[:space:]]*    { BEGIN(CBLOCK);  PARSE(CFC_TOKENTYPE_CBLOCK_START); }
<CBLOCK>__END_C__    { BEGIN(INITIAL); PARSE(CFC_TOKENTYPE_CBLOCK_CLOSE); }
<CBLOCK>(__END_C_[^_]|[^_])+   { SAVE_AND_PARSE(CFC_TOKENTYPE_BLOB); }
           
    /* Parse docucomments, but skip ordinary comments */
"/**"([^*]|"*"[^/])*"*/" { SAVE_AND_PARSE(CFC_TOKENTYPE_DOCUCOMMENT); }
"/*"([^*]|"*"[^/])*"*/"

[ \t\r\n]  /* Skip whitespace. */
<*>.       { 
                printf("Bad input character '%s' at line %d\n", yytext, yylineno);
                yyterminate();
           }
<<EOF>>    { yyterminate(); }
%%

