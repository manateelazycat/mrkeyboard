all: main
main: ../../interface/base_interface.vala \
      ../../interface/multiview/interface.vala \
      ../../interface/multiview/buffer.vala \
      ../../interface/multiview/window.vala \
      ../../lib/draw.vala \
      ../../lib/keymap.vala \
      ../../lib/listview.vala \
      ../../lib/utils.vala \
      current_dir.c \
      tag_id3.vala \
      application.vala
	valac -o main \
    --pkg=clutter-1.0 \
    --pkg=clutter-gtk-1.0 \
    --pkg=clutter-x11-1.0 \
    --pkg=gdk-x11-3.0 \
    --pkg=gee-1.0 \
    --pkg=gtk+-3.0 \
    ../../interface/base_interface.vala \
    ../../interface/multiview/interface.vala \
    ../../interface/multiview/buffer.vala \
    ../../interface/multiview/window.vala \
    ../../lib/draw.vala \
    ../../lib/keymap.vala \
    ../../lib/listview.vala \
    ../../lib/utils.vala \
    current_dir.c \
    tag_id3.vala \
    application.vala
clean:
	rm main
