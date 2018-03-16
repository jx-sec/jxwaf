#include <stdio.h>
#include <string.h>
#include <vector>
#include "ac.h"

using namespace std;

/////////////////////////////////////////////////////////////////////////
//
//         Test using strings from input files
//
/////////////////////////////////////////////////////////////////////////
//
class BigFileTester {
public:
    BigFileTester(const char* filepath);

private:
    void Genector
privaete:
    const char* _msg;
    int _msg_len;
    int _key_num;     // number of strings in dictionary
    int _key_len_idx;
};

/////////////////////////////////////////////////////////////////////////
//
//          Simple (yet maybe tricky) testings
//
/////////////////////////////////////////////////////////////////////////
//
typedef struct {
    const char* str;
    const char* match;
} StrPair;

typedef struct {
    const char* name;
    const char** dict;
    StrPair* strpairs;
    int dict_len;
    int strpair_num;
} TestingCase;

class Tests {
public:
    Tests(const char* name,
          const char* dict[], int dict_len,
          StrPair strpairs[], int strpair_num) {
        if (!_tests)
            _tests = new vector<TestingCase>;

        TestingCase tc;
        tc.name = name;
        tc.dict = dict;
        tc.strpairs = strpairs;
        tc.dict_len = dict_len;
        tc.strpair_num = strpair_num;
        _tests->push_back(tc);
    }

    static vector<TestingCase>* Get_Tests() { return _tests; }
    static void Erase_Tests() { delete _tests; _tests = 0; }

private:
    static vector<TestingCase> *_tests;
};

vector<TestingCase>* Tests::_tests = 0;

static void
simple_test(void) {
    int total = 0;
    int fail = 0;

    vector<TestingCase> *tests = Tests::Get_Tests();
    if (!tests)
        return 0;

    for (vector<TestingCase>::iterator i = tests->begin(), e = tests->end();
            i != e; i++) {
        TestingCase& t = *i;
        fprintf(stdout, ">Testing %s\nDictionary:[ ", t.name);
        for (int i = 0, e = t.dict_len, need_break=0; i < e; i++) {
            fprintf(stdout, "%s, ", t.dict[i]);
            if (need_break++ == 16) {
                fputs("\n  ", stdout);
                need_break = 0;
            }
        }
        fputs("]\n", stdout);

        /* Create the dictionary */
        int dict_len = t.dict_len;
        ac_t* ac = ac_create(t.dict, dict_len);

        for (int ii = 0, ee = t.strpair_num; ii < ee; ii++, total++) {
            const StrPair& sp = t.strpairs[ii];
            const char *str = sp.str; // the string to be matched
            const char *match = sp.match;

            fprintf(stdout, "[%3d] Testing '%s' : ", total, str);

            int len = strlen(str);
            ac_result_t r = ac_match(ac, str, len);
            int m_b = r.match_begin;
            int m_e = r.match_end;

            // The return value per se is insane.
            if (m_b > m_e ||
                ((m_b < 0 || m_e < 0) && (m_b != -1 || m_e != -1))) {
                fprintf(stdout, "Insane return value (%d, %d)\n", m_b, m_e);
                fail ++;
                continue;
            }

            // If the string is not supposed to match the dictionary.
            if (!match) {
                if (m_b != -1 || m_e != -1) {
                    fail ++;
                    fprintf(stdout, "Not Supposed to match (%d, %d) \n",
                            m_b, m_e);
                } else
                    fputs("Pass\n", stdout);
                continue;
            }

            // The string or its substring is match the dict.
            if (m_b >= len || m_b >= len) {
                fail ++;
                fprintf(stdout,
                        "Return value >= the length of the string (%d, %d)\n",
                        m_b, m_e);
                continue;
            } else {
                int mlen = strlen(match);
                if ((mlen != m_e - m_b + 1) ||
                    strncmp(str + m_b, match, mlen)) {
                    fail ++;
                    fprintf(stdout, "Fail\n");
                } else
                    fprintf(stdout, "Pass\n");
            }
        }
        fputs("\n", stdout);
        ac_free(ac);
    }

    fprintf(stdout, "Total : %d, Fail %d\n", total, fail);

    return fail ? -1 : 0;
}

int
main (int argc, char** argv) {
    int res = simple_test();
    return res;
};

/* test 1*/
const char *dict1[] = {"he", "she", "his", "her"};
StrPair strpair1[] = {
    {"he", "he"}, {"she", "she"}, {"his", "his"},
    {"hers", "he"}, {"ahe", "he"}, {"shhe", "he"},
    {"shis2", "his"}, {"ahhe", "he"}
};
Tests test1("test 1",
            dict1, sizeof(dict1)/sizeof(dict1[0]),
            strpair1, sizeof(strpair1)/sizeof(strpair1[0]));

/* test 2*/
const char *dict2[] = {"poto", "poto"}; /* duplicated strings*/
StrPair strpair2[] = {{"The pot had a handle", 0}};
Tests test2("test 2", dict2, 2, strpair2, 1);

/* test 3*/
const char *dict3[] = {"The"};
StrPair strpair3[] = {{"The pot had a handle", "The"}};
Tests test3("test 3", dict3, 1, strpair3, 1);

/* test 4*/
const char *dict4[] = {"pot"};
StrPair strpair4[] = {{"The pot had a handle", "pot"}};
Tests test4("test 4", dict4, 1, strpair4, 1);

/* test 5*/
const char *dict5[] = {"pot "};
StrPair strpair5[] = {{"The pot had a handle", "pot "}};
Tests test5("test 5", dict5, 1, strpair5, 1);

/* test 6*/
const char *dict6[] = {"ot h"};
StrPair strpair6[] = {{"The pot had a handle", "ot h"}};
Tests test6("test 6", dict6, 1, strpair6, 1);

/* test 7*/
const char *dict7[] = {"andle"};
StrPair strpair7[] = {{"The pot had a handle", "andle"}};
Tests test7("test 7", dict7, 1, strpair7, 1);
