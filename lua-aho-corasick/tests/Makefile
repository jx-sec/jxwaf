OS := $(shell uname)
ifeq ($(OS), Darwin)
    SO_EXT := dylib
else
    SO_EXT := so
endif

.PHONY = all clean test runtest benchmark

PROGRAM = ac_test
BENCHMARK = ac_bench
all: runtest

CXXFLAGS = -O3 -g -march=native -Wall -DDEBUG
MYCXXFLAGS = -MMD -I.. $(CXXFLAGS)
%.o : %.cxx
	$(CXX) $< -c $(MYCXXFLAGS)

-include dep.cxx
SRC = test_main.cxx ac_test_simple.cxx ac_test_aggr.cxx test_bigfile.cxx

OBJ = ${SRC:.cxx=.o}

-include test_dep.txt
-include bench_dep.txt

$(PROGRAM) $(BENCHMARK) : testinput/text.tar testinput/image.bin
$(PROGRAM) : $(OBJ) ../libac.$(SO_EXT)
	$(CXX) $(OBJ) -L.. -lac -o $@
	-cat *.d > test_dep.txt

$(BENCHMARK) : ac_bench.o ../libac.$(SO_EXT)
	$(CXX) ac_bench.o -L.. -lac -o $@
	-cat *.d > bench_dep.txt

ifneq ($(OS), Darwin)
runtest:$(PROGRAM)
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):.. ./$(PROGRAM) testinput/*

benchmark:$(BENCHMARK)
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):.. ./ac_bench

else
runtest:$(PROGRAM)
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH):.. ./$(PROGRAM) testinput/*

benchmark:$(BENCHMARK)
	DYLD_LIBRARY_PATH=$(DYLD_LIBRARY_PATH):.. ./ac_bench

endif

testinput/text.tar:
	echo "download testing files (gcc tarball)..."
	if [ ! -d testinput ] ; then mkdir testinput; fi
	cd testinput && \
	curl ftp://ftp.gnu.org/gnu/gcc/gcc-1.42.tar.gz -o text.tar.gz 2>/dev/null \
    && gzip -d text.tar.gz

testinput/image.bin:
	echo "download testing files.."
	if [ ! -d testinput ] ; then mkdir testinput; fi
	curl http://www.3dvisionlive.com/sites/default/files/Curiosity_render_hiresb.jpg -o $@ 2>/dev/null

clean:
	-rm -f *.o *.d dep.txt $(PROGRAM) $(BENCHMARK)
