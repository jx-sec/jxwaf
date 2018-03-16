#ifndef AC_FAST_H
#define AC_FAST_H

#include <vector>
#include "ac.h"
#include "ac_slow.hpp"

using namespace std;

class ACS_Constructor;

typedef uint32 AC_Ofst;
typedef uint32 State_ID;

// The entire "fast" AC graph is converted from its "slow" version, and store
// in an consecutive trunk of memory or "buffer". Since the pointers in the
// fast AC graph are represented as offset relative to the base address of
// the buffer, this fast AC graph is position-independent, meaning cloning
// the fast graph is just to memcpy the entire buffer.
//
// The buffer is laid-out as following:
//
//   1. The buffer header. (i.e. the AC_Buffer content)
//   2. root-node's goto functions. It is represented as an array indiced by
//      root-node's valid inputs, and the element is the ID of the corresponding
//      transition state (aka kid). To save space, we used 8-bit to represent
//      the IDs. ID of root's kids starts with 1.
//
//        Root may have 255 valid inputs. In this speical case, i-th element
//      stores value i -- i.e the i-th state. So, we don't need such array
//      at all. On the other hand, 8-bit is insufficient to encode kids' ID.
//
//   3. An array indiced by state's id, and the element is the offset
//      of correspoding state wrt the base address of the buffer.
//
//   4. the contents of states.
//
typedef struct {
    buf_header_t hdr;         // The header exposed to the user using this lib.
#ifdef VERIFY
    ACS_Constructor* slow_impl;
#endif
    uint32 buf_len;
    AC_Ofst root_goto_ofst;   // addr of root node's goto() function.
    AC_Ofst states_ofst_ofst; // addr of state pointer vector (indiced by id)
    AC_Ofst first_state_ofst; // addr of the first state in the buffer.
    uint16 root_goto_num;     // fan-out of root-node.
    uint16 state_num;         // number of states

    // Followed by the gut of the buffer:
    // 1. map: root's-valid-input -> kid's id
    // 2. map: state's ID -> offset of the state
    // 3. states' content.
} AC_Buffer;

// Depict the state of "fast" AC graph.
typedef struct {
    // transition are sorted. For instance, state s1, has two transitions :
    //   goto(b) -> S_b, goto(a)->S_a. The inputs are sorted in the ascending
    // order, and the target states are permuted accordingly. In this case,
    // the inputs are sorted as : a, b, and the target states are permuted
    // into S_a, S_b. So, S_a is the 1st kid, the ID of kids are consecutive,
    // so we don't need to save all the target kids.
    //
    State_ID first_kid;
    AC_Ofst fail_link;
    short depth;             // How far away from root.
    unsigned short is_term;  // Is terminal node. if is_term != 0, it encodes
                             // the value of "1 + pattern-index".
    unsigned char goto_num;  // The number of valid transition.
    InputTy input_vect[1];   // Vector of valid input. Must be last field!
} AC_State;

class Buf_Allocator {
public:
    Buf_Allocator() : _buf(0) {}
    virtual ~Buf_Allocator() { free(); }

    virtual AC_Buffer* alloc(int sz) = 0;
    virtual void free() {};
protected:
    AC_Buffer* _buf;
};

// Convert slow-AC-graph into fast one.
class AC_Converter {
public:
    AC_Converter(ACS_Constructor& acs, Buf_Allocator& ba) :
        _acs(acs), _buf_alloc(ba) {}
    AC_Buffer* Convert();

private:
    // Return the size in byte needed to to save the specified state.
    uint32 Calc_State_Sz(const ACS_State *) const;

    // In fast-AC-graph, the ID is bit trikcy. Given a state of slow-graph,
    // this function is to return the ID of its counterpart in the fast-graph.
    State_ID Get_Renumbered_Id(const ACS_State *s) const {
        const vector<uint32> &m = _id_map;
        return m[s->Get_ID()];
    }

    AC_Buffer* Alloc_Buffer();
    void Populate_Root_Goto_Func(AC_Buffer *, GotoVect&);

#ifdef DEBUG
    void dump_buffer(AC_Buffer*, FILE*);
#endif

private:
    ACS_Constructor& _acs;
    Buf_Allocator& _buf_alloc;

    // map: ID of state in slow-graph -> ID of counterpart in fast-graph.
    vector<uint32> _id_map;

    // map: ID of state in slow-graph -> offset of counterpart in fast-graph.
    vector<AC_Ofst> _ofst_map;
};

ac_result_t Match(AC_Buffer* buf, const char* str, uint32 len);
ac_result_t Match_Longest_L(AC_Buffer* buf, const char* str, uint32 len);

#endif  // AC_FAST_H
