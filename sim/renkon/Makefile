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
RAND     = ruby ../../utils/rand.rb

.PHONY: data all clean

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
	$(RAND) 2880  > $(DATADIR)/input_renkon_top.dat
	$(RAND) 25000 > $(DATADIR)/weight_renkon_top.dat
	$(RAND) 50    > $(DATADIR)/bias_renkon_top.dat
	$(RAND) 1024  > $(DATADIR)/input_linebuf.dat
	$(RAND) 25000 > $(DATADIR)/input_conv_tree25.dat
	$(RAND) 25000 > $(DATADIR)/filter_conv_tree25.dat

