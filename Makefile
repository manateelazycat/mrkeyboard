CFLAGS := `pkg-config clutter-1.0 clutter-gtk-1.0 mx-1.0 --cflags`  -Wall -g
LDFLAGS := `pkg-config clutter-1.0 clutter-gtk-1.0 mx-1.0 --libs`

all: main
main: main.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
clean:
	rm main
