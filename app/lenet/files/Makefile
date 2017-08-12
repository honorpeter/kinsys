APP = lenet

# Add any other object files to this list below
APP_OBJS  = main.o
APP_OBJS += lenet.o layer.o peta.o util.o

CFLAGS = -std=c11 -Wall

all: build

build: $(APP)

# main.o: peta.o lenet.o util.o layer.o

$(APP): $(APP_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	-rm -f $(APP) *.elf *.gdb *.o

