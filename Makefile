all: main
main: main.vala titlebar.vala image_button.vala draw.vala utils.vala keymap.vala window_manager.vala
	valac --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-x11-3.0 --pkg=gio-2.0 --pkg=xcb --vapidir=./lib main.vala titlebar.vala image_button.vala draw.vala utils.vala window_manager.vala keymap.vala 
clean:
	rm main
