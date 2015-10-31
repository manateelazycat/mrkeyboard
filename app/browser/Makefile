all: main
main: ../../interface/clone/window.vala ../../interface/clone/clone_window.vala ../../interface/base_interface.vala ../../interface/clone/interface.vala application.vala ../../lib/utils.vala ../../lib/keymap.vala
	valac -o main --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=webkitgtk-3.0 --pkg=libsoup-2.4 --vapidir=./lib --pkg=gee-1.0 ../../interface/clone/window.vala ../../interface/clone/clone_window.vala ../../interface/base_interface.vala ../../interface/clone/interface.vala  ../../lib/utils.vala ../../lib/keymap.vala application.vala
clean:
	rm main
