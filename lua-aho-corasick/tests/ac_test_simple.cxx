#include <stdio.h>
#include <string.h>
#include <vector>
#include <string>

#include "ac.h"
#include "ac_util.hpp"
#include "test_base.hpp"

using namespace std;

namespace {
typedef struct {
    const char* str;
    const char* match;
} StrPair;

typedef enum {
    MV_FIRST_MATCH = 0,
    MV_LEFT_LONGEST = 1,
} MatchVariant;

typedef struct {
    const char* name;
    const char** dict;
    StrPair* strpairs;
    int dict_len;
    int strpair_num;
    MatchVariant match_variant;
} TestingCase;

class Tests {
public:
    Tests(const char* name,
          const char* dict[], int dict_len,
          StrPair strpairs[], int strpair_num,
          MatchVariant mv = MV_FIRST_MATCH) {
        if (!_tests)
            _tests = new vector<TestingCase>;

        TestingCase tc;
        tc.name = name;
        tc.dict = dict;
        tc.strpairs = strpairs;
        tc.dict_len = dict_len;
        tc.strpair_num = strpair_num;
        tc.match_variant = mv;
        _tests->push_back(tc);
    }

    static vector<TestingCase>* Get_Tests() { return _tests; }
    static void Erase_Tests() { delete _tests; _tests = 0; }

private:
    static vector<TestingCase> *_tests;
};

class LeftLongestTests : public Tests {
public:
    LeftLongestTests (const char* name, const char* dict[], int dict_len,
                      StrPair strpairs[], int strpair_num):
        Tests(name, dict, dict_len, strpairs, strpair_num, MV_LEFT_LONGEST) {
    }
};

vector<TestingCase>* Tests::_tests = 0;

class ACTestSimple: public ACTestBase {
public:
    ACTestSimple(const char* banner) : ACTestBase(banner) {}
    virtual bool Run();

private:
    void PrintSummary(int total, int fail)  {
        fprintf(stdout, "Test count : %d, fail: %d\n", total, fail);
        fflush(stdout);
    }
};
}

bool
ACTestSimple::Run() {
    int total = 0;
    int fail = 0;

    vector<TestingCase> *tests = Tests::Get_Tests();
    if (!tests) {
        PrintSummary(0, 0);
        return true;
    }

    for (vector<TestingCase>::iterator i = tests->begin(), e = tests->end();
            i != e; i++) {
        TestingCase& t = *i;
        int dict_len = t.dict_len;
        unsigned int* strlen_v = new unsigned int[dict_len];

        fprintf(stdout, ">Testing %s\nDictionary:[ ", t.name);
        for (int i = 0, need_break=0; i < dict_len; i++) {
            const char* s = t.dict[i];
            fprintf(stdout, "%s, ", s);
            strlen_v[i] = strlen(s);
            if (need_break++ == 16) {
                fputs("\n  ", stdout);
                need_break = 0;
            }
        }
        fputs("]\n", stdout);

        /* Create the dictionary */
        ac_t* ac = ac_create(t.dict, strlen_v, dict_len);
        delete[] strlen_v;

        for (int ii = 0, ee = t.strpair_num; ii < ee; ii++, total++) {
            const StrPair& sp = t.strpairs[ii];
            const char *str = sp.str; // the string to be matched
            const char *match = sp.match;

            fprintf(stdout, "[%3d] Testing '%s' : ", total, str);

            int len = strlen(str);
            ac_result_t r;
            if (t.match_variant == MV_FIRST_MATCH)
                r = ac_match(ac, str, len);
            else if (t.match_variant == MV_LEFT_LONGEST)
                r = ac_match_longest_l(ac, str, len);
            else {
                ASSERT(false && "Unknown variant");
            }

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

    PrintSummary(total, fail);
    return fail == 0;
}

bool
Run_AC_Simple_Test() {
    ACTestSimple t("AC Simple test");
    t.PrintBanner();
    return t.Run();
}

//////////////////////////////////////////////////////////////////////////////
//
//    Testing cases for first-match variant (i.e. test ac_match())
//
//////////////////////////////////////////////////////////////////////////////
//

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

const char *dict8[] = {"aaab"};
StrPair strpair8[] = {{"aaaaaaab", "aaab"}};
Tests test8("test 8", dict8, 1, strpair8, 1);

const char *dict9[] = {"haha", "z"};
StrPair strpair9[] = {{"aaaaz", "z"}, {"z", "z"}};
Tests test9("test 9", dict9, 2, strpair9, 2);

/* test the case when input string dosen't contain even a single char
 * of the pattern in dictionary.
 */
const char *dict10[] = {"abc"};
StrPair strpair10[] = {{"cde", 0}};
Tests test10("test 10", dict10, 1, strpair10, 1);


//////////////////////////////////////////////////////////////////////////////
//
//    Testing cases for first longest match variant (i.e.
// test ac_match_longest_l())
//
//////////////////////////////////////////////////////////////////////////////
//

// This was actually first motivation for left-longest-match
const char *dict100[] = {"Mozilla", "Mozilla Mobile"};
StrPair strpair100[] = {{"User Agent containing string Mozilla Mobile", "Mozilla Mobile"}};
LeftLongestTests test100("l_test 100", dict100, 2, strpair100, 1);

// Dict with single char is tricky
const char *dict101[] = {"a", "abc"};
StrPair strpair101[] = {{"abcdef", "abc"}};
LeftLongestTests test101("l_test 101", dict101, 2, strpair101, 1);

// Testing case with partially overlapping patterns. The purpose is to
// check if the fail-link leading from terminal state is correct.
//
// The fail-link leading from terminal-state does not matter in
// match-first-occurrence variant, as it stop when a terminal is hit.
//
const char *dict102[] = {"abc", "bcdef"};
StrPair strpair102[] = {{"abcdef", "bcdef"}};
LeftLongestTests test102("l_test 102", dict102, 2, strpair102, 1);
