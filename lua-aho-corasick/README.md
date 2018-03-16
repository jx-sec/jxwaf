aho-corasick-lua
================

C++ and Lua Implementation of the Aho-Corasick (AC) string matching algorithm
(http://dl.acm.org/citation.cfm?id=360855).

We began with pure Lua implementation and realize the performance is not
satisfactory. So we switch to C/C++ implementation.

There are two shared objects provied by this package: libac.so and ahocorasick.so
The former is a regular shared object which can be directly used by C/C++
application, or by Lua via FFI; and the later is a Lua module. An example usage
is shown bellow:

```lua
local ac = require "ahocorasick"
local dict = {"string1", "string", "etc"}
local acinst = ac.create(dict)
local r = ac.match(acinst, "mystring")
```

For efficiency reasons, the implementation is slightly different from the
standard AC algorithm in that it doesn't return a set of strings in the dictionary
that match the given string, instead it only returns one of them in case the string
matches. The functionality of our implementation can be (precisely) described by
following pseudo-c snippet.

```C
string foo(input-string, dictionary) {
    string ret = the-end-of-input-string;
    for each string s in dictionary {
        // find the first occurrence match sub-string.
        ret = min(ret, strstr(input-string, s);
    }
    return ret;
}
```

It's pretty easy to get rid of this limitation, just to associate each state with
a spare bit-vector dipicting the set of strings recognized by that state.
