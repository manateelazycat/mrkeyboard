all: main
main: ../../interface/clone/window.vala ../../interface/clone/clone_window.vala ../../interface/clone/interface.vala application.vala
	valac -o main --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=vte-2.90 --pkg=gee-1.0 ../../interface/clone/window.vala ../../interface/clone/clone_window.vala ../../interface/clone/interface.vala application.vala
clean:
	rm main
