all: main
main: ../../interface/clone/window.vala ../../interface/clone/clone_window.vala ../../interface/clone/interface.vala  ../../lib/utils.vala application.vala
	valac -o main --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=gtksourceview-3.0 --pkg=gee-1.0 --vapidir=./lib ../../interface/clone/window.vala ../../interface/clone/clone_window.vala ../../interface/clone/interface.vala  ../../lib/utils.vala application.vala
clean:
	rm main
