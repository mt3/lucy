/* Charmonizer/Core/Compiler.h
 */

#ifndef H_CHAZ_COMPILER
#define H_CHAZ_COMPILER

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include "Charmonizer/Core/Defines.h"

typedef struct chaz_Compiler chaz_Compiler;
struct chaz_OperSys;

/* Attempt to compile and link an executable.  Return true if the executable
 * file exists after the attempt.
 */
typedef chaz_bool_t
(*chaz_CC_compile_exe_t)(chaz_Compiler *self, const char *source_path, 
                         const char *exe_path, const char *code, 
                         size_t code_len);

/* Attempt to compile an object file.  Return true if the object file
 * exists after the attempt.
 */
typedef chaz_bool_t
(*chaz_CC_compile_obj_t)(chaz_Compiler *self, const char *source_path, 
                         const char *obj_path, const char *code, 
                         size_t code_len);

/* Add an include directory which will be used for all future compilation
 * attempts.
 */
typedef void
(*chaz_CC_add_inc_dir_t)(chaz_Compiler *self, const char *dir);

/* Destructor.
 */
typedef void
(*chaz_CC_destroy_t)(chaz_Compiler *self);

struct chaz_Compiler {
    struct chaz_OperSys *os;
    char          *cc_command;
    char          *cc_flags;
    char          *include_flag;
    char          *object_flag;
    char          *exe_flag;
    char         **inc_dirs;
    chaz_CC_compile_exe_t compile_exe;
    chaz_CC_compile_obj_t compile_obj;
    chaz_CC_add_inc_dir_t add_inc_dir;
    chaz_CC_destroy_t     destroy;
};

/** Constructor.
 */
chaz_Compiler*
chaz_CC_new(struct chaz_OperSys *oper_sys, const char *cc_command, 
            const char *cc_flags);

#ifdef CHAZ_USE_SHORT_NAMES
  #define Compiler                    chaz_Compiler
  #define CC_compile_exe_t            chaz_CC_compile_exe_t
  #define CC_compile_obj_t            chaz_CC_compile_obj_t
  #define CC_add_inc_dir_t            chaz_CC_add_inc_dir_t
  #define CC_destroy_t                chaz_CC_destroy_t
  #define CC_new                      chaz_CC_new
#endif

#ifdef __cplusplus
}
#endif

#endif /* H_CHAZ_COMPILER */

/**
 * Copyright 2006 The Apache Software Foundation
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

