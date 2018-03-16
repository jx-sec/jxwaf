// Interface functions for libac.so
//
#include <vector>
#include <string>
#include "ac_slow.hpp"
#include "ac_fast.hpp"
#include "ac.h" // for the definition of ac_result_t
#include "ac_util.hpp"

extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
}

#if defined(USE_SLOW_VER)
#error "Not going to implement it"
#endif

using namespace std;
static const char* tname = "aho-corasick";

class BufAlloc : public Buf_Allocator {
public:
    BufAlloc(lua_State* L) : _L(L) {}
    virtual AC_Buffer* alloc(int sz) {
        return (AC_Buffer*)lua_newuserdata (_L, sz);
    }

    // Let GC to take care.
    virtual void free() {}

private:
    lua_State* _L;
};

static bool
_create_helper(lua_State* L, const vector<const char*>& str_v,
               const vector<unsigned int>& strlen_v) {
    ASSERT(str_v.size() == strlen_v.size());

    ACS_Constructor acc;
    BufAlloc ba(L);

    // Step 1: construt the slow version.
    unsigned int strnum = str_v.size();
    const char** str_vect = new const char*[strnum];
    unsigned int* strlen_vect = new unsigned int[strnum];

    int idx = 0;
    for (vector<const char*>::const_iterator i = str_v.begin(), e = str_v.end();
         i != e; i++) {
        str_vect[idx++] = *i;
    }

    idx = 0;
    for (vector<unsigned int>::const_iterator i = strlen_v.begin(),
            e = strlen_v.end(); i != e; i++) {
        strlen_vect[idx++] = *i;
    }

    acc.Construct(str_vect, strlen_vect, idx);
    delete[] str_vect;
    delete[] strlen_vect;

    // Step 2: convert to fast version
    AC_Converter cvt(acc, ba);
    return cvt.Convert() != 0;
}

static ac_result_t
_match_helper(buf_header_t* ac, const char *str, unsigned int len) {
    AC_Buffer* buf = (AC_Buffer*)(void*)ac;
    ASSERT(ac->magic_num == AC_MAGIC_NUM);

    ac_result_t r = Match(buf, str, len);
    return r;
}

// LUA sematic:
//  input: array of strings
//  output: userdata containing the AC-graph (i.e. the AC_Buffer).
//
static int
lac_create(lua_State* L) {
    // The table of the array must be the 1st argument.
    int input_tab = 1;

    luaL_checktype(L, input_tab, LUA_TTABLE);

    // Init the "iteartor".
    lua_pushnil(L);

    vector<const char*> str_v;
    vector<unsigned int> strlen_v;

    // Loop over the elements
    while (lua_next(L, input_tab)) {
        size_t str_len;
        const char* s = luaL_checklstring(L, -1, &str_len);
        str_v.push_back(s);
        strlen_v.push_back(str_len);

        // remove the value, but keep the key as the iterator.
        lua_pop(L, 1);
    }

    // pop the nil value
    lua_pop(L, 1);

    if (_create_helper(L, str_v, strlen_v)) {
        // The AC graph, as a userdata is already pushed to the stack, hence 1.
        return 1;
    }

    return 0;
}

// LUA input:
//    arg1: the userdata, representing the AC graph, returned from l_create().
//    arg2: the string to be matched.
//
// LUA return:
//    if match, return index range of the match; otherwise nil is returned.
//
static int
lac_match(lua_State* L) {
    buf_header_t* ac = (buf_header_t*)lua_touserdata(L, 1);
    if (!ac) {
        luaL_checkudata(L, 1, tname);
        return 0;
    }

    size_t len;
    const char* str;
    #if LUA_VERSION_NUM >= 502
        str = luaL_tolstring(L, 2, &len);
    #else
        str = lua_tolstring(L, 2, &len);
    #endif
    if (!str) {
        luaL_checkstring(L, 2);
        return 0;
    }

    ac_result_t r = _match_helper(ac, str, len);
    if (r.match_begin != -1) {
        lua_pushinteger(L, r.match_begin);
        lua_pushinteger(L, r.match_end);
        return 2;
    }

    return 0;
}

static const struct luaL_Reg lib_funcs[] = {
    { "create", lac_create },
    { "match",  lac_match },
    {0, 0}
};

extern "C" int AC_EXPORT
luaopen_ahocorasick(lua_State* L) {
    luaL_newmetatable(L, tname);

#if LUA_VERSION_NUM == 501
    luaL_register(L, tname, lib_funcs);
#elif LUA_VERSION_NUM >= 502
    luaL_newlib(L, lib_funcs);
#else
    #error "Don't know how to do it right"
#endif
    return 1;
}
