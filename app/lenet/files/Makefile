APP = lenet

# Add any other object files to this list below
APP_OBJS  = main.o
APP_OBJS += lenet.o layer.o peta.o util.o

CFLAGS = -std=c11 -Wall -save-temps -g

all: build

build: $(APP)

# main.o: peta.o lenet.o util.o layer.o

$(APP): $(APP_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(APP_OBJS) $(LDLIBS)

clean:
	-rm -f $(APP) *.elf *.gdb *.o

# install:
# 	install -d data $(DESTDIR)/etc
# 	install -a "# some text here" $(DESTDIR)/etc/syslog.conf
