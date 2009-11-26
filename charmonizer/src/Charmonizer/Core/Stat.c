#define CHAZ_USE_SHORT_NAMES

#include <stdlib.h>
#include <string.h>

#include "Charmonizer/Core/Stat.h"

#include "Charmonizer/Core/Compiler.h"
#include "Charmonizer/Core/HeadCheck.h"
#include "Charmonizer/Core/ModHandler.h"
#include "Charmonizer/Core/OperSys.h"
#include "Charmonizer/Core/Util.h"

static chaz_bool_t initialized    = false;
static chaz_bool_t stat_available = false;

/* lazily compile _charm_stat */
static void
S_init();

void
Stat_stat(const char *filepath, Stat *target)
{
    char *stat_output;
    size_t output_len;

    /* failsafe */
    target->valid = false;

    /* lazy init */
    if (!initialized)
        S_init();

    /* bail out if we didn't succeed in compiling/using _charm_stat */
    if (!stat_available)
        return;

    /* run _charm_stat */
    Util_remove_and_verify("_charm_statout");
    ModHand_os->run_local(ModHand_os, "_charm_stat ", filepath, NULL);
    stat_output = Util_slurp_file("_charm_statout", &output_len);
    Util_remove_and_verify("_charm_statout");

    /* parse the output of _charm_stat and store vars in Stat struct */
    if (stat_output != NULL) {
        char *end_ptr = stat_output;
        target->size     = strtol(stat_output, &end_ptr, 10);
        stat_output      = end_ptr;
        target->blocks   = strtol(stat_output, &end_ptr, 10);
        target->valid = true;
    }

    return;
}

/* source code for the _charm_stat utility */
static char charm_stat_code[] = METAQUOTE
    #include <stdio.h>
    #include <sys/stat.h>
    int main(int argc, char **argv) {
        FILE *out_fh = fopen("_charm_statout", "w+");
        struct stat st;
        if (argc != 2)
            return 1;
        if (stat(argv[1], &st) == -1)
            return 2;
        fprintf(out_fh, "%ld %ld\n", (long)st.st_size, (long)st.st_blocks);
        return 0;
    }
METAQUOTE;

static void
S_init()
{
    /* only try this once */
    initialized = true;
    if (Util_verbosity)
        printf("Attempting to compile _charm_stat utility...\n");

    /* bail if sys/stat.h isn't available */
    if (!HeadCheck_check_header("sys/stat.h"))
        return;

    /* if the compile succeeds, open up for business */
    stat_available = ModHand_compiler->compile_exe(ModHand_compiler, 
        "_charm_stat.c", "_charm_stat", charm_stat_code, strlen(charm_stat_code));
    remove("_charm_stat.c");
}


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
