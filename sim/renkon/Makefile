#ref = "http://urin.github.io/posts/2013/simple-makefile-for-clang/"

COMPILER = clang++
CFLAGS   = -g -std=c++14 -O3 \
           -Wall -Wextra -Winit-self -Wno-unused-parameter -Wfloat-equal
INCLUDE  = -I../common
LDFLAGS  =
LIBS     =
SOURCES  = $(wildcard *.cpp)
TARGET   = $(SOURCES:.cpp=.dat)
DATADIR  = ../../data/$(shell basename `pwd`)
RAND     = python3 ../../utils/rand.py

.PHONY: data all clean hoge

%.dat: %.out data
	./$< > $(DATADIR)/true_$@

%.out: %.o $(LIBS)
	$(COMPILER) -o $@ $(LDFLAGS) $^

%.o: %.cpp
	$(COMPILER) -o $@ $(CFLAGS) $(INCLUDE) -c $<

all: $(TARGET)

clean:
	rm -f $(TARGET:.cpp=.out)

data:
	mkdir -p $(DATADIR)
	$(RAND) 3072  > $(DATADIR)/input_renkon_top.dat
	$(RAND) 12800 > $(DATADIR)/weight_renkon_top.dat
	$(RAND) 32    > $(DATADIR)/bias_renkon_top.dat
	$(RAND) 1024  > $(DATADIR)/input_renkon_linebuf.dat
	$(RAND) 192   > $(DATADIR)/input_renkon_linebuf_pad.dat
	$(RAND) 25000 > $(DATADIR)/input_renkon_conv_tree25.dat
	$(RAND) 25000 > $(DATADIR)/filter_renkon_conv_tree25.dat

hoge:
	make debug.out
	./debug_gen.rb
	./debug.out

