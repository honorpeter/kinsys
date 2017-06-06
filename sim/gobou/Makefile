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
	$(RAND) 800    > $(DATADIR)/input_gobou_top.dat
	$(RAND) 400000 > $(DATADIR)/weight_gobou_top.dat
	$(RAND) 500    > $(DATADIR)/bias_gobou_top.dat

