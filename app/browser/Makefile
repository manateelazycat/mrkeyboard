all: main
main: ../../interface/window.vala ../../interface/clone_window.vala ../../interface/interface.vala application.vala ../../lib/utils.vala ../../lib/keymap.vala
	valac -o main --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=webkitgtk-3.0 --pkg=libsoup-2.4 --vapidir=./lib --pkg=gee-1.0 ../../interface/window.vala ../../interface/clone_window.vala ../../interface/interface.vala  ../../lib/utils.vala ../../lib/keymap.vala application.vala
clean:
	rm main
