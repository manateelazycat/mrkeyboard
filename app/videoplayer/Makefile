all: main
main: ../../interface/base_interface.vala \
      ../../interface/clone/interface.vala \
      ../../interface/clone/window.vala \
      ../../interface/clone/clone_window.vala \
      ../../lib/draw.vala \
      ../../lib/utils.vala \
      application.vala
	valac -o main \
    --pkg=clutter-1.0 \
    --pkg=clutter-gtk-1.0 \
    --pkg=clutter-x11-1.0 \
    --pkg=gdk-x11-3.0 \
    --pkg=gee-1.0 \
    --pkg=gtk+-3.0 \
    ../../interface/base_interface.vala \
    ../../interface/clone/interface.vala \
    ../../interface/clone/window.vala \
    ../../interface/clone/clone_window.vala \
	../../lib/draw.vala \
    ../../lib/utils.vala \
    application.vala
clean:
	rm main
