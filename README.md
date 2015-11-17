# Mr. keyboard

**Description**:

Top hacker like live in emacs, keyboard control everything...
Unfortunately, emacs can't do everything, such as web browser, GUI multimedia application, power tool in real world.

Why not build everything with keyboard?
Like emacs style, but this time, we rebuild everything scratch from Mr. keyboard.

This is OS for top hacker, enjoy it. ;)

## Dependencies

vala-0.28, clutter-1.0, clutter-gtk-1.0, clutter-x11-1.0, gtk+-3.0, gdk-x11-3.0, gio-2.0, xcb

## Install

Install dependencies
> sudo apt-get install valac gir1.2-gee-1.0 libgee-dev libgtk-3-dev libwebkitgtk-3.0-dev libclutter-1.0-dev libclutter-gtk-1.0-dev libgtksourceview-3.0-dev libgexiv2-dev libpoppler-glib-dev libvte-2.90-dev libsqlite3-dev uuid-runtime -y

Build mrkeyboard main program
> make

Build mrkeyboard applications
> ./build_apps make

## Usage

Start build mrkeyboard
> ./main

## TODO

* Fixed clutter clone issue: maybe cause by clutter new version.
* Fixed event pass to child process.
* Write IRC application for hacking team communication.
* Write wifi-share for hacking at TV. ;) (https://github.com/albfan/miraclecast)
* Design search framework.
* Design application package standard.
* Design keystroke standard and build one-key system for feature. ;)
* Implement package manager and smart notify bar.
* Write english completion plugins to make my figure faster. 
* Write hackable editor that powerful as emacs, then we can reach editor-strap. 
* Add welcome page.
* Research Atom editor, steal nice feature. ;)

## Hacking mission
* Image viewer: add rotate features.
* Image viewer: add zoom-out/zoom-in features.
* Image viewer: add nagivater.
* Music player: use faster way to get duration.
* Browser: write js vimium plugin.
* Make browser support flash.
* Switch mode with osd style.

## BUG

* Make window resize as normal, not bigger and bigger.

## Getting involved

This project just start, any idea and suggestion are welcome.

You can contact me with lazycat.manatee@gmail.com 

