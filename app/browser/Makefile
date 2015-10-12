all: main
main: ../../interface/main.vala ../../interface/window.vala ../../interface/clone_window.vala ../../interface/interface.vala application.vala
	valac --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=webkitgtk-3.0 --pkg=libsoup-2.4 --vapidir=./lib --pkg=gee-1.0 ../../interface/main.vala ../../interface/window.vala ../../interface/clone_window.vala ../../interface/interface.vala application.vala
clean:
	rm main
