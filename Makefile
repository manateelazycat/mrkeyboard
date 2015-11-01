all: main
main: ./lib/draw.vala \
      ./lib/keymap.vala \
      ./lib/utils.vala \
      application.vala \
      image_button.vala \
      tabbar.vala \
      titlebar.vala  \
      window.vala \
      window_manager.vala \
      window_mode.vala \
      window_rectangle.vala \
      main.vala
	valac -o main \
    --pkg=clutter-1.0 \
    --pkg=clutter-gtk-1.0 \
    --pkg=clutter-x11-1.0 \
    --pkg=gdk-x11-3.0 \
    --pkg=gee-1.0 \
    --pkg=gio-2.0 \
    --pkg=gtk+-3.0 \
    --pkg=json-glib-1.0 \
    --pkg=xcb \
    --vapidir=./lib \
    ./lib/draw.vala \
    ./lib/keymap.vala \
    ./lib/utils.vala \
    application.vala \
    image_button.vala \
    tabbar.vala \
    titlebar.vala \
    window.vala \
    window_manager.vala \
	window_mode.vala \
    window_rectangle.vala \
    main.vala
clean:
	rm main
