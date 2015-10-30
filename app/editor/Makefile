all: main
main: ../../interface/multiview/window.vala ../../interface/multiview/clone_window.vala ../../interface/multiview/interface.vala ../../interface/multiview/buffer.vala  ../../lib/utils.vala application.vala
	valac -o main --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=gtksourceview-3.0 --pkg=gee-1.0 --vapidir=./lib ../../interface/multiview/window.vala ../../interface/multiview/clone_window.vala ../../interface/multiview/interface.vala ../../interface/multiview/buffer.vala  ../../lib/utils.vala application.vala
clean:
	rm main
