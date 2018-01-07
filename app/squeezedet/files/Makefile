APP = squeezedet

# Add any other object files to this list below
APP_OBJS  = main.o
APP_OBJS += squeezedet.o layer.o peta.o util.o

CXXFLAGS = -std=c++14 -Wall

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	-rm -f $(APP) *.elf *.gdb *.o
