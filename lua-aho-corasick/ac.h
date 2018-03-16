#ifndef AC_H
#define AC_H
#ifdef __cplusplus
extern "C" {
#endif

#define AC_EXPORT __attribute__ ((visibility ("default")))

/* If the subject-string dosen't match any of the given patterns, "match_begin"
 * should be a negative; otherwise the substring of the subject-string,
 * starting from offset "match_begin" to "match_end" incusively,
 * should exactly match the pattern specified by the 'pattern_idx' (i.e.
 * the pattern is "pattern_v[pattern_idx]" where the "pattern_v" is the
 * first acutal argument passing to ac_create())
 */
typedef struct {
    int match_begin;
    int match_end;
    int pattern_idx;
} ac_result_t;

struct ac_t;

/* Create an AC instance. "pattern_v" is a vector of patterns, the length of
 * i-th pattern is specified by "pattern_len_v[i]"; the number of patterns
 * is specified by "vect_len".
 *
 * Return the instance on success, or NUL otherwise.
 */
ac_t* ac_create(const char** pattern_v, unsigned int* pattern_len_v,
                unsigned int vect_len) AC_EXPORT;

ac_result_t ac_match(ac_t*, const char *str, unsigned int len) AC_EXPORT;

ac_result_t ac_match_longest_l(ac_t*, const char *str, unsigned int len) AC_EXPORT;

/* Similar to ac_match() except that it only returns match-begin. The rationale
 * for this interface is that luajit has hard time in dealing with strcture-
 * return-value.
 */
int ac_match2(ac_t*, const char *str, unsigned int len) AC_EXPORT;

void ac_free(void*) AC_EXPORT;

#ifdef __cplusplus
}
#endif

#endif /* AC_H */
