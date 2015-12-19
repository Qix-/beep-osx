beep:
	$(CC) $(CFLAGS) -obj -Wall -framework Cocoa -framework AudioToolbox -framework AudioUnit beep.m -lxopt -o beep

install: beep
	cp beep /usr/local/bin/beep

clean:
	rm -rf beep
