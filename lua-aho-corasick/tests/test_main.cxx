#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>
#include <string.h>
#include <vector>
#include <string>
#include "ac.h"
#include "ac_util.hpp"
#include "test_base.hpp"

using namespace std;


/////////////////////////////////////////////////////////////////////////
//
//          Simple (yet maybe tricky) testings
//
/////////////////////////////////////////////////////////////////////////
//
int
main (int argc, char** argv) {
    bool succ = Run_AC_Simple_Test();

    vector<const char*> files;
    for (int i = 1; i < argc; i++) { files.push_back(argv[i]); }
    succ = Run_AC_Aggressive_Test(files) && succ;

    return succ ? 0 : -1;
};
