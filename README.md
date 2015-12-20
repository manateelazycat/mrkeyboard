# Mr. keyboard

I, finger and my keyboard ...

**Description**:

Top hacker like live in emacs, keyboard control everything...
Unfortunately, emacs can't do everything, such as web browser, GUI multimedia application, power tool in real world.

Why not build everything with keyboard?
Like emacs style, but this time, we rebuild everything scratch from Mr. keyboard.

This is OS for top hacker, enjoy it. ;)

## Install

Install dependencies
> sudo apt-get install valac gir1.2-gee-1.0 libgee-dev libgtk-3-dev libwebkitgtk-3.0-dev libclutter-1.0-dev libclutter-gtk-1.0-dev libgtksourceview-3.0-dev libgexiv2-dev libpoppler-glib-dev libvte-2.90-dev libsqlite3-dev uuid-runtime mplayer2 -y

Build mrkeyboard main program
> make

Build mrkeyboard applications
> ./build_apps make

## Usage

Start mrkeyboard
> ./main

## TODO

* editor: next-line/prev-line: cursor move screen line, not logic line.
* editor: next-line/prev-line handle screen scroll.
* editor: move forward/backward char.
* editor: move forward/backward word.
* editor: move line home/end.
* editor: scroll screen up/down.
* editor: move to first non-blank char.
* editor: kill line.
* editor: kill to line home/end.
* editor: kill forward/backward char.
* editor: kill forward/backward word.
* editor: add mark and mark switch.
* editor: copy, paste, and insert.
* editor: select to scroll screen.
* editor: add text parser and syntax highlight.
* Write IRC application for hacking team communication.
* Research Atom editor, steal nice feature. ;)
* Write wifi-share for hacking at TV. ;) (https://github.com/albfan/miraclecast)
* Design search framework.
* Design application package standard.
* Design keystroke standard and build one-key system for feature. ;)
* Implement package manager and smart notify bar.
* Write english completion plugins to make my figure faster. 
* Add welcome page.
* Fixed event pass to child process. (Wait deepin window manager fix)

## Hacking missions
* Image viewer: add rotate features.
* Image viewer: add zoom-out/zoom-in features.
* Image viewer: add nagivater.
* Music player: use faster way to get duration.
* Browser: write js vimium plugin.
* Make browser support flash.
* Switch mode with osd style.
* Make window resize as normal, not bigger and bigger.

## Getting involved

This project just start, any idea and suggestion are welcome.

You can contact me with lazycat.manatee@gmail.com 

