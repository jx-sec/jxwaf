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

///////////////////////////////////////////////////////////////////////////
//
//      Implementation of BigFileTester
//
///////////////////////////////////////////////////////////////////////////
//
BigFileTester::BigFileTester(const char* filepath) {
    _filepath = filepath;
    _fd = -1;
    _msg = (char*)MAP_FAILED;
    _msg_len = 0;
    _key_num = 0;
    _chunk_sz = 0;
    _chunk_num = 0;

    _max_key_num = 100;
    _key_min_len = 20;
    _key_max_len = 80;
}

void
BigFileTester::Cleanup() {
    if (_msg != MAP_FAILED) {
        munmap((void*)_msg, _msg_len);
        _msg = (char*)MAP_FAILED;
        _msg_len = 0;
    }

    if (_fd != -1) {
        close(_fd);
        _fd = -1;
    }
}

bool
BigFileTester::GenerateKeys() {
    int chunk_sz = 4096;
    int max_key_num = _max_key_num;
    int key_min_len = _key_min_len;
    int key_max_len = _key_max_len;

    int t = _msg_len / chunk_sz;
    int keynum = t > max_key_num ? max_key_num : t;

    if (keynum <= 4) {
        // file is too small
        return false;
    }
    chunk_sz = _msg_len / keynum;
    _chunk_sz = chunk_sz;

    // For each chunck, "randomly" grab a sub-string searving
    // as key.
    int random_ofst[] = { 12, 30, 23, 15 };
    int rofstsz = sizeof(random_ofst)/sizeof(random_ofst[0]);
    int ofst = 0;
    const char* msg = _msg;
    _chunk_num = keynum - 1;
    for (int idx = 0, e = _chunk_num; idx < e; idx++) {
        const char* key = msg + ofst + idx % rofstsz;
        int key_len = key_min_len + idx % (key_max_len - key_min_len);
        _keys.push_back(StrInfo(key, key_len));
        ofst += chunk_sz;
    }
    return true;
}

bool
BigFileTester::Run() {
    // Step 1: Bring the file into memory
    fprintf(stdout, "Testing using file '%s'...\n", _filepath);

    int fd = _fd = ::open(_filepath, O_RDONLY);
    if (fd == -1) {
        perror("open");
        return false;
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        perror("fstat");
        return false;
    }

    if (!S_ISREG (sb.st_mode)) {
        fprintf(stderr, "%s is not regular file\n", _filepath);
        return false;
    }

    int ten_M = 1024 * 1024 * 10;
    int map_sz = _msg_len = sb.st_size > ten_M ? ten_M : sb.st_size;
    char* p = _msg =
        (char*)mmap (0, map_sz, PROT_READ|PROT_WRITE, MAP_PRIVATE, fd, 0);
    if (p == MAP_FAILED) {
        perror("mmap");
        return false;
    }

    // Get rid of '\0' if we are picky at it.
    if (Str_C_Style()) {
        for (int i = 0; i < map_sz; i++) { if (!p[i]) p[i] = 'a'; }
        p[map_sz - 1] = 0;
    }

    // Step 2: "Fabricate" some keys from the file.
    if (!GenerateKeys()) {
        close(fd);
        return false;
    }

    // Step 3: Create PM instance
    const char** keys = new const char*[_keys.size()];
    unsigned int* keylens = new unsigned int[_keys.size()];

    int i = 0;
    for (vector<StrInfo>::iterator si = _keys.begin(), se = _keys.end();
         si != se; si++, i++) {
        const StrInfo& strinfo = *si;
        keys[i] = strinfo.first;
        keylens[i] = strinfo.second;
    }

    buf_header_t* PM = PM_Create(keys, keylens, i);
    delete[] keys;
    delete[] keylens;

    // Step 4: Run testing
    bool res = Run_Helper(PM);
    PM_Free(PM);

    // Step 5: Clanup
    munmap(p, map_sz);
    _msg = (char*)MAP_FAILED;
    close(fd);
    _fd = -1;

    fprintf(stdout, "%s\n", res ? "succ" : "fail");
    return res;
}

void
BigFileTester::PrintStr(FILE* f, const char* str, int len) {
    fprintf(f, "{");
    for (int i = 0; i < len; i++) {
        unsigned char c = str[i];
        if (isprint(c))
           fprintf(f, "'%c', ", c);
        else
           fprintf(f, "%#x, ", c);
    }
    fprintf(f, "}");
};
