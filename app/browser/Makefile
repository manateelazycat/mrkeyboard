all: main
main: ../../interface/base_interface.vala \
      ../../interface/clone/interface.vala \
      ../../interface/clone/window.vala \
      ../../interface/clone/clone_window.vala \
      ../../lib/utils.vala \
      ../../lib/keymap.vala \
      application.vala
	valac -o main \
	-X -w \
    --pkg=clutter-1.0 \
    --pkg=clutter-gtk-1.0 \
    --pkg=clutter-x11-1.0 \
    --pkg=gdk-x11-3.0 \
    --pkg=gee-1.0 \
    --pkg=gtk+-3.0 \
    --pkg=libsoup-2.4 \
    --pkg=webkitgtk-3.0 \
    --vapidir=./lib \
    ../../interface/base_interface.vala \
    ../../interface/clone/interface.vala \
    ../../interface/clone/window.vala \
    ../../interface/clone/clone_window.vala \
    ../../lib/utils.vala \
    ../../lib/keymap.vala \
    application.vala
clean:
	rm -f main
