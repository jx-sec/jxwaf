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

namespace {
class ACBigFileTester : public BigFileTester {
public:
    ACBigFileTester(const char* filepath) : BigFileTester(filepath){};

private:
    virtual buf_header_t* PM_Create(const char** strv, uint32* strlenv,
                                    uint32 vect_len) {
        return (buf_header_t*)ac_create(strv, strlenv, vect_len);
    }

    virtual void PM_Free(buf_header_t* PM) { ac_free(PM); }
    virtual bool Run_Helper(buf_header_t* PM);
};

class ACTestAggressive: public ACTestBase {
public:
    ACTestAggressive(const vector<const char*>& files, const char* banner)
        : ACTestBase(banner), _files(files) {}
    virtual bool Run();

private:
    void PrintSummary(int total, int fail)  {
        fprintf(stdout, "Test count : %d, fail: %d\n", total, fail);
        fflush(stdout);
    }
    vector<const char*> _files;
};

} // end of anonymous namespace

bool
ACBigFileTester::Run_Helper(buf_header_t* PM) {
    int fail = 0;
    // advance one chunk at a time.
    int len = _msg_len;
    int chunk_sz = _chunk_sz;

    vector<const char*> c_style_keys;
    for (int i = 0, e = _keys.size(); i != e; i++) {
        const char* key = _keys[i].first;
        int len = _keys[i].second;
        char *t = new char[len+1];
        memcpy(t, key, len);
        t[len] = '\0';
        c_style_keys.push_back(t);
    }

    for (int ofst = 0, chunk_idx = 0, chunk_num = _chunk_num;
         chunk_idx < chunk_num; ofst += chunk_sz, chunk_idx++) {
        const char* substring = _msg + ofst;
        ac_result_t r = ac_match((ac_t*)(void*)PM, substring , len - ofst);
        int m_b = r.match_begin;
        int m_e = r.match_end;

        if (m_b < 0 || m_e < 0 || m_e <= m_b || m_e >= len) {
            fprintf(stdout, "fail to find match substring[%d:%d])\n",
                    ofst, len - 1);
            fail ++;
            continue;
        }

        const char* match_str = _msg + len;
        int strstr_len = 0;
        int key_idx = -1;

        for (int i = 0, e = c_style_keys.size(); i != e; i++) {
            const char* key = c_style_keys[i];
            if (const char *m = strstr(substring, key)) {
                if (m < match_str) {
                    match_str = m;
                    strstr_len = _keys[i].second;
                    key_idx = i;
                }
            }
        }
        ASSERT(key_idx != -1);
        if ((match_str - substring != m_b)) {
            fprintf(stdout,
                   "Fail to find match substring[%d:%d]),"
                   " expected to find match at offset %d instead of %d\n",
                    ofst, len - 1,
                    (int)(match_str - _msg), ofst + m_b);
            fprintf(stdout, "%d vs %d (key idx %d)\n", strstr_len, m_e - m_b + 1, key_idx);
            PrintStr(stdout, match_str, strstr_len);
            fprintf(stdout, "\n");
            PrintStr(stdout, _msg + ofst + m_b,
                     m_e - m_b + 1);
            fprintf(stdout, "\n");
            fail ++;
        }
    }
    for (vector<const char*>::iterator i = c_style_keys.begin(),
            e = c_style_keys.end(); i != e; i++) {
        delete[] *i;
    }

    return fail == 0;
}

bool
ACTestAggressive::Run() {
    int fail = 0;
    for (vector<const char*>::iterator i = _files.begin(), e = _files.end();
         i != e; i++) {
        ACBigFileTester bft(*i);
        if (!bft.Run())
            fail ++;
    }
    return fail == 0;
}

bool
Run_AC_Aggressive_Test(const vector<const char*>& files) {
    ACTestAggressive t(files, "AC Aggressive test");
    t.PrintBanner();
    return t.Run();
}
