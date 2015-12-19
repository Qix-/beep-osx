beep:
	$(CC) $(CFLAGS) -obj -Wall -framework Cocoa -framework AudioToolbox -framework AudioUnit beep.m -lxopt -o beep
