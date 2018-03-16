// Interface functions for libac.so
//
#include "ac_slow.hpp"
#include "ac_fast.hpp"
#include "ac.h"

static inline ac_result_t
_match(buf_header_t* ac, const char* str, unsigned int len) {
    AC_Buffer* buf = (AC_Buffer*)(void*)ac;
    ASSERT(ac->magic_num == AC_MAGIC_NUM);

    ac_result_t r = Match(buf, str, len);

    #ifdef VERIFY
    {
        Match_Result r2 = buf->slow_impl->Match(str, len);
        if (r.match_begin != r2.begin) {
            ASSERT(0);
        } else {
            ASSERT((r.match_begin < 0) ||
                   (r.match_end == r2.end &&
                    r.pattern_idx == r2.pattern_idx));
        }
    }
    #endif
    return r;
}

extern "C" int
ac_match2(ac_t* ac, const char* str, unsigned int len) {
    ac_result_t r = _match((buf_header_t*)(void*)ac, str, len);
    return r.match_begin;
}

extern "C" ac_result_t
ac_match(ac_t* ac, const char* str, unsigned int len) {
    return _match((buf_header_t*)(void*)ac, str, len);
}

extern "C" ac_result_t
ac_match_longest_l(ac_t* ac, const char* str, unsigned int len) {
    AC_Buffer* buf = (AC_Buffer*)(void*)ac;
    ASSERT(((buf_header_t*)ac)->magic_num == AC_MAGIC_NUM);

    ac_result_t r = Match_Longest_L(buf, str, len);
    return r;
}

class BufAlloc : public Buf_Allocator {
public:
    virtual AC_Buffer* alloc(int sz) {
        return (AC_Buffer*)(new unsigned char[sz]);
    }

    // Do not de-allocate the buffer when the BufAlloc die.
    virtual void free() {}

    static void myfree(AC_Buffer* buf) {
        ASSERT(buf->hdr.magic_num == AC_MAGIC_NUM);
        const char* b = (const char*)buf;
        delete[] b;
    }
};

extern "C" ac_t*
ac_create(const char** strv, unsigned int* strlenv, unsigned int v_len) {
    if (v_len >= 65535) {
        // TODO: Currently we use 16-bit to encode pattern-index (see the
        //  comment to AC_State::is_term), therefore we are not able to
        //  handle pattern set with more than 65535 entries.
        return 0;
    }

    ACS_Constructor *acc;
#ifdef VERIFY
    acc = new ACS_Constructor;
#else
    ACS_Constructor tmp;
    acc = &tmp;
#endif
    acc->Construct(strv, strlenv, v_len);

    BufAlloc ba;
    AC_Converter cvt(*acc, ba);
    AC_Buffer* buf = cvt.Convert();

#ifdef VERIFY
    buf->slow_impl = acc;
#endif
    return (ac_t*)(void*)buf;
}

extern "C" void
ac_free(void* ac) {
    AC_Buffer* buf = (AC_Buffer*)ac;
#ifdef VERIFY
    delete buf->slow_impl;
#endif

    BufAlloc::myfree(buf);
}
