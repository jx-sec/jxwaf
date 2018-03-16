#include <algorithm>    // for std::sort
#include "ac_slow.hpp"
#include "ac_fast.hpp"

uint32
AC_Converter::Calc_State_Sz(const ACS_State* s) const {
    AC_State dummy;
    uint32 sz = offsetof(AC_State, input_vect);
    sz += s->Get_GotoNum() * sizeof(dummy.input_vect[0]);

    if (sz < sizeof(AC_State))
        sz = sizeof(AC_State);

    uint32 align = __alignof__(dummy);
    sz = (sz + align - 1) & ~(align - 1);
    return sz;
}

AC_Buffer*
AC_Converter::Alloc_Buffer() {
    const vector<ACS_State*>& all_states = _acs.Get_All_States();
    const ACS_State* root_state = _acs.Get_Root_State();
    uint32 root_fanout = root_state->Get_GotoNum();

    // Step 1: Calculate the buffer size
    AC_Ofst root_goto_ofst, states_ofst_ofst, first_state_ofst;

    // part 1 :  buffer header
    uint32 sz = root_goto_ofst = sizeof(AC_Buffer);

    // part 2: Root-node's goto function
    if (likely(root_fanout != 255))
        sz += 256;
    else
        root_goto_ofst = 0;

    // part 3: mapping of state's relative position.
    unsigned align = __alignof__(AC_Ofst);
    sz = (sz + align - 1) & ~(align - 1);
    states_ofst_ofst = sz;

    sz += sizeof(AC_Ofst) * all_states.size();

    // part 4: state's contents
    align = __alignof__(AC_State);
    sz = (sz + align - 1) & ~(align - 1);
    first_state_ofst = sz;

    uint32 state_sz = 0;
    for (vector<ACS_State*>::const_iterator i = all_states.begin(),
            e = all_states.end(); i != e; i++) {
        state_sz += Calc_State_Sz(*i);
    }
    state_sz -= Calc_State_Sz(root_state);

    sz += state_sz;

    // Step 2: Allocate buffer, and populate header.
    AC_Buffer* buf = _buf_alloc.alloc(sz);

    buf->hdr.magic_num = AC_MAGIC_NUM;
    buf->hdr.impl_variant = IMPL_FAST_VARIANT;
    buf->buf_len = sz;
    buf->root_goto_ofst = root_goto_ofst;
    buf->states_ofst_ofst = states_ofst_ofst;
    buf->first_state_ofst = first_state_ofst;
    buf->root_goto_num = root_fanout;
    buf->state_num = _acs.Get_State_Num();
    return buf;
}

void
AC_Converter::Populate_Root_Goto_Func(AC_Buffer* buf,
                                      GotoVect& goto_vect) {
    unsigned char *buf_base = (unsigned char*)(buf);
    InputTy* root_gotos = (InputTy*)(buf_base + buf->root_goto_ofst);
    const ACS_State* root_state = _acs.Get_Root_State();

    root_state->Get_Sorted_Gotos(goto_vect);

    // Renumber the ID of root-node's immediate kids.
    uint32 new_id = 1;
    bool full_fantout = (goto_vect.size() == 255);
    if (likely(!full_fantout))
        bzero(root_gotos, 256*sizeof(InputTy));

    for (GotoVect::iterator i = goto_vect.begin(), e = goto_vect.end();
            i != e; i++, new_id++) {
        InputTy c = i->first;
        ACS_State* s = i->second;
        _id_map[s->Get_ID()] = new_id;

        if (likely(!full_fantout))
            root_gotos[c] = new_id;
    }
}

AC_Buffer*
AC_Converter::Convert() {
    // Step 1: Some preparation stuff.
    GotoVect gotovect;

    _id_map.clear();
    _ofst_map.clear();
    _id_map.resize(_acs.Get_Next_Node_Id());
    _ofst_map.resize(_acs.Get_Next_Node_Id());

    // Step 2: allocate buffer to accommodate the entire AC graph.
    AC_Buffer* buf = Alloc_Buffer();
    unsigned char* buf_base = (unsigned char*)buf;

    // Step 3: Root node need special care.
    Populate_Root_Goto_Func(buf, gotovect);
    buf->root_goto_num = gotovect.size();
    _id_map[_acs.Get_Root_State()->Get_ID()] = 0;

    // Step 4: Converting the remaining states by BFSing the graph.
    // First of all, enter root's immediate kids to the working list.
    vector<const ACS_State*> wl;
    State_ID id = 1;
    for (GotoVect::iterator i = gotovect.begin(), e = gotovect.end();
            i != e; i++, id++) {
        ACS_State* s = i->second;
        wl.push_back(s);
        _id_map[s->Get_ID()] = id;
    }

    AC_Ofst* state_ofst_vect = (AC_Ofst*)(buf_base + buf->states_ofst_ofst);
    AC_Ofst ofst = buf->first_state_ofst;
    for (uint32 idx = 0; idx < wl.size(); idx++) {
        const ACS_State* old_s = wl[idx];
        AC_State* new_s = (AC_State*)(buf_base + ofst);

        // This property should hold as we:
        //  - States are appended to worklist in the BFS order.
        //  - sibiling states are appended to worklist in the order of their
        //    corresponding input.
        //
        State_ID state_id = idx + 1;
        ASSERT(_id_map[old_s->Get_ID()] == state_id);

        state_ofst_vect[state_id] = ofst;

        new_s->first_kid = wl.size() + 1;
        new_s->depth = old_s->Get_Depth();
        new_s->is_term = old_s->is_Terminal() ?
                         old_s->get_Pattern_Idx() + 1 : 0;

        uint32 gotonum = old_s->Get_GotoNum();
        new_s->goto_num = gotonum;

        // Populate the "input" field
        old_s->Get_Sorted_Gotos(gotovect);
        uint32 input_idx = 0;
        uint32 id = wl.size() + 1;
        InputTy* input_vect = new_s->input_vect;
        for (GotoVect::iterator i = gotovect.begin(), e = gotovect.end();
             i != e; i++, id++, input_idx++) {
            input_vect[input_idx] = i->first;

            ACS_State* kid = i->second;
            _id_map[kid->Get_ID()] = id;
            wl.push_back(kid);
        }

        _ofst_map[old_s->Get_ID()] = ofst;
        ofst += Calc_State_Sz(old_s);
    }

    // This assertion might be useful to catch buffer overflow
    ASSERT(ofst == buf->buf_len);

    // Populate the fail-link field.
    for (vector<const ACS_State*>::iterator i = wl.begin(), e = wl.end();
            i != e; i++) {
        const ACS_State* slow_s = *i;
        State_ID fast_s_id = _id_map[slow_s->Get_ID()];
        AC_State* fast_s = (AC_State*)(buf_base + state_ofst_vect[fast_s_id]);
        if (const ACS_State* fl = slow_s->Get_FailLink()) {
            State_ID id = _id_map[fl->Get_ID()];
            fast_s->fail_link = id;
        } else
            fast_s->fail_link = 0;
    }
#ifdef DEBUG
    //dump_buffer(buf, stderr);
#endif
    return buf;
}

static inline AC_State*
Get_State_Addr(unsigned char* buf_base, AC_Ofst* StateOfstVect, uint32 state_id) {
    ASSERT(state_id != 0 && "root node is handled in speical way");
    ASSERT(state_id < ((AC_Buffer*)buf_base)->state_num);
    return (AC_State*)(buf_base + StateOfstVect[state_id]);
}

// The performance of the binary search is critical to this work.
//
// Here we provide two versions of binary-search functions.
// The non-pristine version seems to consistently out-perform "pristine" one on
// bunch of benchmarks we tested.  With the benchmark under tests/testinput/
//
//   The speedup is following on my laptop (core i7, ubuntu):
//
//   benchmark       was                is
//  ----------------------------------------
//  image.bin       2.3s               2.0s
//  test.tar        6.7s               5.7s
//
//  NOTE: As of I write this comment, we only measure the performance on about
// 10+ benchmarks. It's still too early to say which one works better.
//
#if !defined(BS_MULTI_VER)
static bool __attribute__((always_inline)) inline
Binary_Search_Input(InputTy* input_vect, int vect_len, InputTy input, int& idx) {
    if (vect_len <= 8) {
        for (int i = 0; i < vect_len; i++) {
            if (input_vect[i] == input) {
                idx = i;
                return true;
            }
        }
        return false;
    }

    // The "low" and "high" must be signed integers, as they could become -1.
    // Also since they are signed integer, "(low + high)/2" is sightly more
    // expensive than (low+high)>>1 or ((unsigned)(low + high))/2.
    //
    int low = 0, high = vect_len - 1;
    while (low <= high) {
        int mid = (low + high) >> 1;
        InputTy mid_c = input_vect[mid];

        if (input < mid_c)
            high = mid - 1;
        else if (input > mid_c)
            low = mid + 1;
        else {
            idx = mid;
            return true;
        }
    }
    return false;
}

#else

/* Let us call this version "pristine" version. */
static inline bool
Binary_Search_Input(InputTy* input_vect, int vect_len, InputTy input, int& idx) {
    int low = 0, high = vect_len - 1;
    while (low <= high) {
        int mid = (low + high) >> 1;
        InputTy mid_c = input_vect[mid];

        if (input < mid_c)
            high = mid - 1;
        else if (input > mid_c)
            low = mid + 1;
        else {
            idx = mid;
            return true;
        }
    }
    return false;
}
#endif

typedef enum {
    // Look for the first match. e.g. pattern set = {"ab", "abc", "def"},
    // subject string "ababcdef". The first match would be "ab" at the
    // beginning of the subject string.
    MV_FIRST_MATCH,

    // Look for the left-most longest match. Follow above example; there are
    // two longest matches, "abc" and "def", and the left-most longest match
    // is "abc".
    MV_LEFT_LONGEST,

    // Similar to the left-most longest match, except that it returns the
    // *right* most longest match. Follow above example, the match would
    // be "def". NYI.
    MV_RIGHT_LONGEST,

    // Return all patterns that match that given subject string. NYI.
    MV_ALL_MATCHES,
} MATCH_VARIANT;

/* The Match_Tmpl is the template for vairants MV_FIRST_MATCH, MV_LEFT_LONGEST,
 * MV_RIGHT_LONGEST (If we really really need MV_RIGHT_LONGEST variant, we are
 * better off implementing it in a seprate function).
 *
 * The Match_Tmpl supports three variants at once "symbolically", once it's
 * instanced to a particular variants, all the code irrelevant to the variants
 * will be statically removed. So don't worry about the code like
 * "if (variant == MV_XXXX)"; they will not incur any penalty.
 *
 * The drawback of using template is increased code size. Unfortunately, there
 * is no silver bullet.
 */
template<MATCH_VARIANT variant> static ac_result_t
Match_Tmpl(AC_Buffer* buf, const char* str, uint32 len) {
    unsigned char* buf_base = (unsigned char*)(buf);
    unsigned char* root_goto = buf_base + buf->root_goto_ofst;
    AC_Ofst* states_ofst_vect = (AC_Ofst* )(buf_base + buf->states_ofst_ofst);

    AC_State* state = 0;
    uint32 idx = 0;

    // Skip leading chars that are not valid input of root-nodes.
    if (likely(buf->root_goto_num != 255)) {
        while(idx < len) {
            unsigned char c = str[idx++];
            if (unsigned char kid_id = root_goto[c]) {
                state = Get_State_Addr(buf_base, states_ofst_vect, kid_id);
                break;
            }
        }
    } else {
        idx = 1;
        state = Get_State_Addr(buf_base, states_ofst_vect, *str);
    }

    ac_result_t r = {-1, -1};
    if (likely(state != 0)) {
        if (unlikely(state->is_term)) {
            /* Dictionary may have string of length 1 */
            r.match_begin = idx - state->depth;
            r.match_end = idx - 1;
            r.pattern_idx = state->is_term - 1;

            if (variant == MV_FIRST_MATCH) {
                return r;
            }
        }
    }

    while (idx < len) {
        unsigned char c = str[idx];
        int res;
        bool found;
        found = Binary_Search_Input(state->input_vect, state->goto_num, c, res);
        if (found) {
            // The "t = goto(c, current_state)" is valid, advance to state "t".
            uint32 kid = state->first_kid + res;
            state = Get_State_Addr(buf_base, states_ofst_vect, kid);
            idx++;
        } else {
            // Follow the fail-link.
            State_ID fl = state->fail_link;
            if (fl == 0) {
                // fail-link is root-node, which implies the root-node dosen't
                // have 255 valid transitions (otherwise, the fail-link should
                // points to "goto(root, c)"), so we don't need speical handling
                // as we did before this while-loop is entered.
                //
                while(idx < len) {
                    InputTy c = str[idx++];
                    if (unsigned char kid_id = root_goto[c]) {
                        state =
                            Get_State_Addr(buf_base, states_ofst_vect, kid_id);
                        break;
                    }
                }
            } else {
                state = Get_State_Addr(buf_base, states_ofst_vect, fl);
            }
        }

        // Check to see if the state is terminal state?
        if (state->is_term) {
            if (variant == MV_FIRST_MATCH) {
                ac_result_t r;
                r.match_begin = idx - state->depth;
                r.match_end = idx - 1;
                r.pattern_idx = state->is_term - 1;
                return r;
            }

            if (variant == MV_LEFT_LONGEST) {
                int match_begin = idx - state->depth;
                int match_end = idx - 1;

                if (r.match_begin == -1 ||
                    match_end - match_begin > r.match_end - r.match_begin) {
                    r.match_begin = match_begin;
                    r.match_end = match_end;
                    r.pattern_idx = state->is_term - 1;
                }
                continue;
            }

            ASSERT(false && "NYI");
        }
    }

    return r;
}

ac_result_t
Match(AC_Buffer* buf, const char* str, uint32 len) {
    return Match_Tmpl<MV_FIRST_MATCH>(buf, str, len);
}

ac_result_t
Match_Longest_L(AC_Buffer* buf, const char* str, uint32 len) {
    return Match_Tmpl<MV_LEFT_LONGEST>(buf, str, len);
}

#ifdef DEBUG
void
AC_Converter::dump_buffer(AC_Buffer* buf, FILE* f) {
    vector<AC_Ofst> state_ofst;
    state_ofst.resize(_id_map.size());

    fprintf(f, "Id maps between old/slow and new/fast graphs\n");
    int old_id = 0;
    for (vector<uint32>::iterator i = _id_map.begin(), e = _id_map.end();
         i != e; i++, old_id++) {
        State_ID new_id = *i;
        if (new_id != 0) {
            fprintf(f, "%d -> %d, ", old_id, new_id);
        }
    }
    fprintf(f, "\n");

    int idx = 0;
    for (vector<uint32>::iterator i = _id_map.begin(), e = _id_map.end();
         i != e; i++, idx++) {
        uint32 id = *i;
        if (id == 0) continue;
        state_ofst[id] = _ofst_map[idx];
    }

    unsigned char* buf_base = (unsigned char*)buf;

    // dump root goto-function.
    fprintf(f, "root, fanout:%d goto {", buf->root_goto_num);
    if (buf->root_goto_num != 255) {
        unsigned char* root_goto = buf_base + buf->root_goto_ofst;
        for (uint32 i = 0; i < 255; i++) {
            if (root_goto[i] != 0)
                fprintf(f, "%c->S:%d, ", (unsigned char)i, root_goto[i]);
        }
    } else {
        fprintf(f, "full fanout\n");
    }
    fprintf(f, "}\n");

    // dump remaining states.
    AC_Ofst* state_ofst_vect = (AC_Ofst*)(buf_base + buf->states_ofst_ofst);
    for (uint32 i = 1, e = buf->state_num; i < e; i++) {
        AC_Ofst ofst = state_ofst_vect[i];
        ASSERT(ofst == state_ofst[i]);
        fprintf(f, "S:%d, ofst:%d, goto={", i, ofst);

        AC_State* s = (AC_State*)(buf_base + ofst);
        State_ID kid = s->first_kid;
        for (uint32 k = 0, ke = s->goto_num; k < ke; k++, kid++)
            fprintf(f, "%c->S:%d, ", s->input_vect[k], kid);

        fprintf(f, "}, fail-link = S:%d, %s\n", s->fail_link,
                s->is_term ? "terminal" : "");
    }
}
#endif
