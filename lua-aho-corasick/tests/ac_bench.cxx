#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <time.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <libgen.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#include <string>
#include <vector>
#include "ac.h"
#include "ac_util.hpp"

using namespace std;

static bool SomethingWrong = false;

static int iteration = 300;
static string dict_dir;
static string obj_file_dir;
static bool print_help = false;
static int piece_size = 1024;

class PatternSet {
public:
    PatternSet(const char* filepath);
    ~PatternSet() { Cleanup(); }

    int getPatternNum() const { return _pat_num; }
    const char** getPatternVector() const { return _patterns; }
    unsigned int* getPatternLenVector() const { return _pat_len; }

    const char* getErrMessage() const { return _errmsg; }
    static bool isDictFile(const char* filepath) {
        if (strncmp(basename(const_cast<char*>(filepath)), "dict", 4))
            return false;
        return true;
    }

private:
    bool ExtractPattern(const char* filepath);
    void Cleanup();

    const char** _patterns;
    unsigned int* _pat_len;
    char* _mmap;
    int _fd;
    size_t _mmap_size;
    int _pat_num;

    const char* _errmsg;
};

bool
PatternSet::ExtractPattern(const char* filepath) {
    if (!isDictFile(filepath))
        return false;

    struct stat filestat;
    if (stat(filepath, &filestat)) {
        _errmsg = "fail to call stat()";
        return false;
    }

    if (filestat.st_size > 4096 * 1024) {
        /* It dosen't seem to be a dictionary file*/
        _errmsg = "file too big?";
        return false;
    }

    _fd = open(filepath, 0);
    if (_fd == -1) {
        _errmsg = "fail to open dictionary file";
        return false;
    }

    _mmap_size = filestat.st_size;
    _mmap = (char*)mmap(0, filestat.st_size, PROT_READ|PROT_WRITE,
                        MAP_PRIVATE, _fd, 0);
    if (_mmap == MAP_FAILED) {
        _errmsg = "fail to call mmap";
        return false;
    }

    const char* pat = _mmap;
    vector<const char*> pat_vect;
    vector<unsigned> pat_len_vect;

    for (size_t i = 0, e = filestat.st_size; i < e; i++) {
        if (_mmap[i] == '\r' || _mmap[i] == '\n') {
            _mmap[i] = '\0';
            int len = _mmap + i - pat;
            if (len > 0) {
                pat_vect.push_back(pat);
                pat_len_vect.push_back(len);
            }
            pat = _mmap + i + 1;
        }
    }

    ASSERT(pat_vect.size() == pat_len_vect.size());

    int pat_num = pat_vect.size();
    if (pat_num > 0) {
        const char** p = _patterns = new const char*[pat_num];
        int i = 0;
        for (vector<const char*>::iterator iter = pat_vect.begin(),
                iter_e = pat_vect.end(); iter != iter_e; ++iter) {
            p[i++] = *iter;
        }

        i = 0;
        unsigned int* q = _pat_len = new unsigned int[pat_num];
        for (vector<unsigned>::iterator iter = pat_len_vect.begin(),
                iter_e = pat_len_vect.end(); iter != iter_e; ++iter) {
            q[i++] = *iter;
        }
    }

    _pat_num = pat_num;
    if (pat_num <= 0) {
        _errmsg = "no pattern at all";
        return false;
    }

    return true;
}

void
PatternSet::Cleanup() {
    if (_mmap != MAP_FAILED) {
        munmap(_mmap, _mmap_size);
        _mmap = (char*)MAP_FAILED;
        _mmap_size = 0;
    }

    delete[] _patterns;
    delete[] _pat_len;
    if (_fd != -1)
        close(_fd);
    _pat_num = -1;
}

PatternSet::PatternSet(const char* filepath) {
     _patterns = 0;
    _pat_len = 0;
     _mmap = (char*)MAP_FAILED;
     _mmap_size = 0;
    _pat_num = -1;
    _errmsg = "";

    if (!ExtractPattern(filepath))
        Cleanup();
}

bool
getFilesUnderDir(vector<string>& files, const char* path) {
    files.clear();

    DIR* dir = opendir(path);
    if (!dir)
        return false;

    string path_dir = path;
    path_dir += "/";

    for (;;) {
        struct dirent* entry = readdir(dir);
        if (entry) {
            string filepath = path_dir + entry->d_name;
            struct stat file_stat;
            if (stat(filepath.c_str(), &file_stat)) {
                closedir(dir);
                return false;
            }

            if (S_ISREG(file_stat.st_mode))
                files.push_back(filepath);

            continue;
        }

        if (errno) {
            return false;
        }
        break;
    }
    closedir(dir);
    return true;
}

class Timer {
public:
    Timer() {
        my_clock_gettime(&_start);
        _stop = _start;
        _acc.tv_sec = 0;
        _acc.tv_nsec = 0;
    }

    const Timer& operator += (const Timer& that) {
        time_t sec = _acc.tv_sec + that._acc.tv_sec;
		long nsec = _acc.tv_nsec + that._acc.tv_nsec;
		if (nsec > 1000000000) {
			nsec -= 1000000000;
			sec += 1;
		}
		_acc.tv_sec = sec;
		_acc.tv_nsec = nsec;
		return *this;
    }

	// return duration in us
    size_t getDuration() const {
		return _acc.tv_sec * (size_t)1000000 + _acc.tv_nsec/1000;
	}

    void Start(bool acc=true) {
        my_clock_gettime(&_start);
    }

    void Stop() {
        my_clock_gettime(&_stop);
        struct timespec t = CalcDuration();
        _acc = add_duration(_acc, t);
    }

private:
    int my_clock_gettime(struct timespec* t) {
#ifdef __linux
        return clock_gettime(CLOCK_PROCESS_CPUTIME_ID, t);
#else
        struct timeval tv;
        int rc = gettimeofday(&tv, 0);
        t->tv_sec = tv.tv_sec;
        t->tv_nsec = tv.tv_usec * 1000;
        return rc;
#endif
    }

    struct timespec add_duration(const struct timespec& dur1,
                                 const struct timespec& dur2) {
        time_t sec = dur1.tv_sec + dur2.tv_sec;
		long nsec = dur1.tv_nsec + dur2.tv_nsec;
		if (nsec > 1000000000) {
			nsec -= 1000000000;
			sec += 1;
		}
        timespec t;
        t.tv_sec = sec;
        t.tv_nsec = nsec;

		return t;
    }

    struct timespec CalcDuration() const {
        timespec diff;
        if ((_stop.tv_nsec - _start.tv_nsec)<0) {
            diff.tv_sec = _stop.tv_sec - _start.tv_sec - 1;
            diff.tv_nsec = 1000000000 + _stop.tv_nsec - _start.tv_nsec;
        } else {
            diff.tv_sec  = _stop.tv_sec - _start.tv_sec;
            diff.tv_nsec = _stop.tv_nsec - _start.tv_nsec;
        }
        return diff;
    }

    struct timespec _start;
    struct timespec _stop;
    struct timespec _acc;
};

class Benchmark {
public:
    Benchmark(const PatternSet& pat_set, const char* infile):
        _pat_set(pat_set), _infile(infile) {
        _mmap = (char*)MAP_FAILED;
        _file_sz = 0;
        _fd = -1;
    }

    ~Benchmark() {
        if (_mmap != MAP_FAILED)
            munmap(_mmap, _file_sz);
        if (_fd != -1)
            close(_fd);
    }

    bool Run(int iteration);
    const Timer& getTimer() const { return _timer; }

private:
    const PatternSet& _pat_set;
    const char* _infile;
    char* _mmap;
    int _fd;
    size_t _file_sz; // input file size
    Timer _timer;
};

bool
Benchmark::Run(int iteration) {
    if (_pat_set.getPatternNum() <= 0) {
        SomethingWrong = true;
        return false;
    }

    if (_mmap == MAP_FAILED) {
        struct stat filestat;
        if (stat(_infile, &filestat)) {
            SomethingWrong = true;
            return false;
        }

        if (!S_ISREG(filestat.st_mode)) {
            SomethingWrong = true;
            return false;
        }

        _fd = open(_infile, 0);
        if (_fd == -1)
            return false;

        _mmap = (char*)mmap(0, filestat.st_size, PROT_READ|PROT_WRITE,
                            MAP_PRIVATE, _fd, 0);

        if (_mmap == MAP_FAILED) {
            SomethingWrong = true;
            return false;
        }

        _file_sz = filestat.st_size;
    }

    ac_t* ac = ac_create(_pat_set.getPatternVector(),
                         _pat_set.getPatternLenVector(),
                         _pat_set.getPatternNum());
    if (!ac) {
        SomethingWrong = true;
        return false;
    }

    int piece_num = _file_sz/piece_size;

    _timer.Start(false);

    /* Stupid compiler may not be able to promote piece_size into register.
     * Do it manually.
     */
    int piece_sz = piece_size;
    for (int i = 0; i < iteration; i++) {
        size_t match_ofst = 0;
        for (int piece_idx = 0; piece_idx <  piece_num; piece_idx ++) {
            ac_match2(ac, _mmap + match_ofst, piece_sz);
            match_ofst += piece_sz;
        }
        if (match_ofst != _file_sz)
            ac_match2(ac, _mmap + match_ofst, _file_sz - match_ofst);
    }
    _timer.Stop();
    return true;
}

const char* short_opt = "hd:f:i:p:";
const struct option long_opts[] = {
    {"help",            no_argument,        0, 'h'},
    {"iteration",       required_argument,  0, 'i'},
    {"dictionary-dir",  required_argument,  0, 'd'},
    {"obj-file-dir",    required_argument,  0, 'f'},
    {"piece-size",      required_argument,  0, 'p'},
};

static void
PrintHelp(const char* prog_name) {
    const char* msg =
"Usage %s [OPTIONS]\n"
"  -d, --dictionary-dir  : specify the dictionary directory (./dict by default)\n"
"  -f, --obj-file-dir    : specify the object file directory\n"
"                          (./testinput by default)\n"
"  -i, --iteration       : Run this many iteration for each pattern match\n"
"  -p, --piece-size      : The size of 'piece' in byte. The input file is\n"
"                          divided into pieces, and match function is working\n"
"                          on one piece at a time. The default size of piece\n"
"                          is 1k byte.\n";

    fprintf(stdout, msg, prog_name);
}

static bool
getOptions(int argc, char** argv) {
    bool dict_dir_set = false;
    bool objfile_dir_set = false;
    int opt_index;

    while (1) {
        if (print_help) break;

        int c = getopt_long(argc, argv, short_opt, long_opts, &opt_index);

        if (c == -1) break;
        if (c == 0) { c = long_opts[opt_index].val; }

        switch(c) {
        case 'h':
            print_help = true;
            break;

        case 'i':
            iteration = atol(optarg);
            break;

        case 'd':
            dict_dir = optarg;
            dict_dir_set = true;
            break;

        case 'f':
            obj_file_dir = optarg;
            objfile_dir_set = true;
            break;

        case 'p':
            piece_size = atol(optarg);
            break;

        case '?':
        default:
            return false;
        }
    }

    if (print_help)
        return true;

    string basedir(dirname(argv[0]));
    if (!dict_dir_set)
       dict_dir = basedir + "/dict";

    if (!objfile_dir_set)
        obj_file_dir = basedir + "/testinput";

    return true;
}

int
main(int argc, char** argv) {
    if (!getOptions(argc, argv))
        return -1;

    if (print_help) {
        PrintHelp(argv[0]);
        return 0;
    }

#ifndef __linux
    fprintf(stdout, "\n!!!WARNING: On this OS, the execution time is measured"
            " by gettimeofday(2) which is imprecise!!!\n\n");
#endif

    fprintf(stdout, "Test with iteration = %d, piece size = %d, and",
            iteration, piece_size);
    fprintf(stdout, "\n  dictionary dir = %s\n  object file dir = %s\n\n",
            dict_dir.c_str(), obj_file_dir.c_str());

    vector<string> dict_files;
    vector<string> input_files;

    if (!getFilesUnderDir(dict_files, dict_dir.c_str())) {
        fprintf(stdout, "fail to find dictionary files\n");
        return -1;
    }

    if (!getFilesUnderDir(input_files, obj_file_dir.c_str())) {
        fprintf(stdout, "fail to find test input files\n");
        return -1;
    }

    for (vector<string>::iterator diter = dict_files.begin(),
        diter_e = dict_files.end(); diter != diter_e; ++diter) {

        const char* dict_name = diter->c_str();
        if (!PatternSet::isDictFile(dict_name))
            continue;

        PatternSet ps(dict_name);
        if (ps.getPatternNum() <= 0) {
            fprintf(stdout, "fail to open dictionary file %s : %s\n",
                    dict_name, ps.getErrMessage());
            SomethingWrong = true;
            continue;
        }

        fprintf(stdout, "Using dictionary %s\n", dict_name);
        Timer timer;
        for (vector<string>::iterator iter = input_files.begin(),
                iter_e = input_files.end(); iter != iter_e; ++iter) {
            fprintf(stdout, "  testing %s ... ", iter->c_str());
            fflush(stdout);
            Benchmark bm(ps, iter->c_str());
            bm.Run(iteration);
            const Timer& t = bm.getTimer();
            timer += bm.getTimer();
            fprintf(stdout, "elapsed %.3f\n", t.getDuration() / 1000000.0);
        }

        fprintf(stdout,
                "\n==========================================================\n"
                " Total Elapse %.3f\n\n", timer.getDuration() / 1000000.0);
    }

    return SomethingWrong ? -1 : 0;
}
