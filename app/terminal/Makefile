all: main
main: main.vala window.vala clone_window.vala interface.vala application.vala
	valac --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=vte-2.90 --pkg=gee-1.0 main.vala window.vala clone_window.vala interface.vala application.vala
clean:
	rm main
