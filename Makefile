all: main
main: main.vala titlebar.vala image_button.vala draw.vala utils.vala
	valac --pkg=clutter-1.0 --pkg=clutter-x11-1.0 --pkg=gtk+-3.0 --pkg=clutter-gtk-1.0 --pkg=gdk-3.0 main.vala titlebar.vala image_button.vala draw.vala utils.vala
clean:
	rm main
