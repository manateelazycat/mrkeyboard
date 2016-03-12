# Mr. keyboard

I, my fingers and my keyboard ...

**Description**

Top hackers like to live in emacs, using keyboard to control everything...
Unfortunately, emacs can't do everything, such as web browsing, GUI multimedia manipulation, and other powerful things in real world.

Why not build everything with keyboard?
Like emacs style, but this time, we rebuild everything scratch from Mr. keyboard.

This is the OS for top hackers, so enjoy it. ;)

## Install

Installation dependencies
> sudo apt-get install valac uuid-runtime mplayer2 libwebkitgtk-3.0-dev libgexiv2-dev libsqlite3-dev gir1.2-gee-1.0 gir1.2-gtk-3.0 gir1.2-clutter-1.0 gir1.2-gtkclutter-1.0 gir1.2-poppler-0.18 gir1.2-vte-2.91 libgee-dev libgtk-3-dev libclutter-1.0-dev libclutter-gtk-1.0-dev libpoppler-glib-dev libvte-2.91-dev -y

Build mrkeyboard main program
> make

Build mrkeyboard applications
> ./build_apps make

## Usage

Start mrkeyboard
> ./mrkeyboard.sh

After starting mrkeyboard, you can use keystrokes below to start applications:

| Keymap           | Function     |
|------------------|--------------|
| **Win** + **u**  | browser      |
| **Win** + **n**  | terminal	  |
| **Win** + **j**  | file manager |

For other programs, such as editors, imageviewers, pdfviewers, videoplayers, musicplayers, you can press Enter in the filemanager to start them.
Filemanager keystrokes are:

| Keymap   | Function             |
|----------|----------------------|
| **j**    | select next file     |
| **k**    | select previous file |
| **f**    | open file            |
| **'**    | previous directory   |

Once you open two or more applications, try keystrokes below:

| Keymap           | Function                  |
|------------------|---------------------------|
| **Alt** + **;**  | split window vertically   |
| **Alt** + **:**  | split window horizontally |
| **Alt** + **'**  | close current window      |
| **Alt** + **"**  | close other windows       |
| **Alt** + **,**  | Select previous tab       |
| **Alt** + **.**  | Select next tab           |
| **Ctrl** + **w** | Close tab                 |
| **Alt** + **<**  | Switch previous mode      |
| **Alt** + **>**  | Switch next mode          |

Because it's still under fast development, start application is not so easy,
I would write a launcher similar to emacs-helm to provide smarter means for application manipulation.

## License

This project is distributed under the terms of GPL3+

## Getting involved

This project is in early stage, any ideas or suggestions are welcome.

You can contact me via lazycat.manatee@gmail.com 



