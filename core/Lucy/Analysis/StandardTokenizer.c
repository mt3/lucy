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

#define C_LUCY_STANDARDTOKENIZER
#define C_LUCY_TOKEN
#include "Lucy/Util/ToolSet.h"

#include "Lucy/Analysis/StandardTokenizer.h"
#include "Lucy/Analysis/Token.h"
#include "Lucy/Analysis/Inversion.h"

/*
 * We use a modified version of the Word_Break property defined in UAX #29.
 * CR, LF, Newline and all undefined characters map to 0. WB_ASingle
 * designates characters that are Alphabetic but are excluded from ALetter.
 * WB_Extend_Format includes characters in both Extend and Format. The other
 * WB_* values correspond to the standard properties.
 *
 * The tables are in a compressed format that uses a three-stage lookup
 * scheme. They're generated with the perl script gen_word_break_tables.pl
 * in devel/bin.
 */

#define WB_ASingle        1
#define WB_ALetter        2
#define WB_Numeric        3
#define WB_Katakana       4
#define WB_ExtendNumLet   5
#define WB_Extend_Format  6
#define WB_MidNumLet      7
#define WB_MidLetter      8
#define WB_MidNum         9

#include "WordBreak.tab"

typedef struct lucy_StringIter {
    size_t byte_pos;
    size_t char_pos;
} lucy_StringIter;

static int
S_parse_single(const char *text, size_t len, lucy_StringIter *iter,
               Inversion *inversion);

static int
S_parse_word(const char *text, size_t len, lucy_StringIter *iter,
             int state, Inversion *inversion);

static int
S_wb_lookup(const char *ptr);

static void
S_iter_advance(const char *text, lucy_StringIter *iter);

static int
S_skip_extend_format(const char *text, size_t len, lucy_StringIter *iter);

StandardTokenizer*
StandardTokenizer_new() {
    StandardTokenizer *self = (StandardTokenizer*)VTable_Make_Obj(STANDARDTOKENIZER);
    return StandardTokenizer_init(self);
}

StandardTokenizer*
StandardTokenizer_init(StandardTokenizer *self) {
    Analyzer_init((Analyzer*)self);
    return self;
}

Inversion*
StandardTokenizer_transform(StandardTokenizer *self, Inversion *inversion) {
    Inversion *new_inversion = Inversion_new(NULL);
    Token *token;

    while (NULL != (token = Inversion_Next(inversion))) {
        StandardTokenizer_Tokenize_Str(self, token->text, token->len,
                                    new_inversion);
    }

    return new_inversion;
}

Inversion*
StandardTokenizer_transform_text(StandardTokenizer *self, CharBuf *text) {
    Inversion *new_inversion = Inversion_new(NULL);
    StandardTokenizer_Tokenize_Str(self, (char*)CB_Get_Ptr8(text),
                                CB_Get_Size(text), new_inversion);
    return new_inversion;
}

void
StandardTokenizer_tokenize_str(StandardTokenizer *self, const char *text,
                               size_t len, Inversion *inversion) {
    lucy_StringIter iter = { 0, 0 };

    while (iter.byte_pos < len) {
        int wb = S_wb_lookup(text + iter.byte_pos);

        while (wb >= WB_ASingle && wb <=  WB_Katakana) {
            if (wb == WB_ASingle) {
                wb = S_parse_single(text, len, &iter, inversion);
            }
            else {
                wb = S_parse_word(text, len, &iter, wb, inversion);
            }
            if (iter.byte_pos >= len) return;
        }

        S_iter_advance(text, &iter);
    }
}

/*
 * Parse a word consisting of a single codepoint followed by extend or
 * format characters. Used for Alphabetic characters that don't have the
 * ALetter word break property: ideographs, Hiragana, and "complex content".
 * Advances the iterator and returns the word break property of the current
 * character.
 */
static int
S_parse_single(const char *text, size_t len, lucy_StringIter *iter,
               Inversion *inversion) {
    lucy_StringIter start = *iter;
    int wb = S_skip_extend_format(text, len, iter);

    Token *token = Token_new(text + start.byte_pos,
                             iter->byte_pos - start.byte_pos,
                             start.char_pos, iter->char_pos, 1.0f, 1);
    Inversion_Append(inversion, token);

    return wb;
}

/*
 * Parse a word starting with an ALetter, Numeric or Katakana character.
 * Advances the iterator and returns the word break property of the current
 * character.
 */
static int
S_parse_word(const char *text, size_t len, lucy_StringIter *iter,
             int state, Inversion *inversion) {
    int wb = -1;
    lucy_StringIter start = *iter;
    S_iter_advance(text, iter);
    lucy_StringIter end = *iter;

    while (iter->byte_pos < len) {
        wb = S_wb_lookup(text + iter->byte_pos);

        switch(wb) {
          case WB_ALetter:
          case WB_Numeric:
          case WB_Katakana:
          case WB_ExtendNumLet:
            state = wb;
            // fall through
          case WB_Extend_Format:
            S_iter_advance(text, iter);
            end = *iter;
            continue;
          case WB_MidNumLet:
          case WB_MidLetter:
          case WB_MidNum:
            if (state == WB_ALetter && wb != WB_MidNum
            ||  state == WB_Numeric && wb != WB_MidLetter) {
                wb = S_skip_extend_format(text, len, iter);

                if (wb == state) {
                    S_iter_advance(text, iter);
                    end = *iter;
                    continue;
                }
            }
          default:
            break;
        }

        break;
    }

    Token *token = Token_new(text + start.byte_pos,
                             end.byte_pos - start.byte_pos,
                             start.char_pos, end.char_pos, 1.0f, 1);
    Inversion_Append(inversion, token);

    return wb;
}

static int
S_wb_lookup(const char *ptr) {
    uint8_t c = *(uint8_t*)ptr++;

    if (c < 0x80) { return wb_table0[c]; }

    uint32_t i2;
    if (c < 0xE0) {
        i2 = c & 0x1F;
    }
    else {
        uint32_t i1;
        if (c < 0xF0) {
            i1 = c & 0x0F;
        }
        else {
            i1 = ((c & 0x07) << 6) | (*ptr++ & 0x3F);
        }
        if (i1 >= WB_TABLE1_SIZE) { return 0; }
        i2 = (wb_table1[i1] << 6) | (*ptr++ & 0x3F);
    }
    uint32_t i3 = (wb_table2[i2] << 6) | (*ptr++ & 0x3F);
    return wb_table3[i3];
}

static void
S_iter_advance(const char *text, lucy_StringIter *iter) {
    iter->byte_pos += StrHelp_UTF8_COUNT[*(uint8_t*)(text + iter->byte_pos)];
    iter->char_pos += 1;
}

/*
 * Advances the iterator skipping over Extend and Format characters.
 * Returns the word break property of the current character.
 */
static int
S_skip_extend_format(const char *text, size_t len, lucy_StringIter *iter) {
    int wb = -1;

    do {
        S_iter_advance(text, iter);
        if (iter->byte_pos >= len) { break; }
        wb = S_wb_lookup(text + iter->byte_pos);
    } while (wb == WB_Extend_Format);

    return wb;
}

bool_t
StandardTokenizer_equals(StandardTokenizer *self, Obj *other) {
    StandardTokenizer *const twin = (StandardTokenizer*)other;
    if (twin == self)                        { return true; }
    if (!Obj_Is_A(other, STANDARDTOKENIZER)) { return false; }
    return true;
}


