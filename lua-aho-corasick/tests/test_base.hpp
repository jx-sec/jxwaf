#ifndef TEST_BASE_H
#define TEST_BASE_H

#include <stdio.h>
#include <string>
#include <stdint.h>

using namespace std;
class ACTestBase {
public:
    ACTestBase(const char* name) :_banner(name) {}
    virtual void PrintBanner() {
        fprintf(stdout, "\n===== %s ====\n", _banner.c_str());
    }

    virtual bool Run() = 0;
private:
    string _banner;
};

typedef std::pair<const char*, int> StrInfo;
class BigFileTester {
public:
    BigFileTester(const char* filepath);
    virtual ~BigFileTester() { Cleanup(); }

    bool Run();

protected:
    virtual buf_header_t* PM_Create(const char** strv, uint32_t* strlenv,
                                    uint32_t vect_len) = 0;
    virtual void PM_Free(buf_header_t*) = 0;
    virtual bool Run_Helper(buf_header_t* PM) = 0;

    // Return true if the '\0' is valid char of a string.
    virtual bool Str_C_Style() { return true; }

    bool GenerateKeys();
    void Cleanup();
    void PrintStr(FILE*, const char* str, int len);

protected:
    const char* _filepath;
    int _fd;
    vector<StrInfo> _keys;
    char* _msg;
    int _msg_len;
    int _key_num;     // number of strings in dictionary
    int _chunk_sz;
    int _chunk_num;

    int _max_key_num;
    int _key_min_len;
    int _key_max_len;
};

extern bool Run_AC_Simple_Test();
extern bool Run_AC_Aggressive_Test(const vector<const char*>& files);

#endif
