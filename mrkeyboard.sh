#!/bin/sh

export CLUTTER_BACKEND=x11
./main $* 2>&1 | stdbuf -o0 grep -ivn -e '^(main:.*It *is *most *likely *synthesized *outside *Gdk/GTK+$'  -e '^(main:.*Missing *name *of *pseudo-class$' -e '^(main:.*Whoever *translated *default:LTR *did *so *wrongly.$' -e '^$' -e '^\*\* (main:[0-9].*): WARNING \*\*: Couldn.* connect to accessibility bus: Failed to connect to socket /tmp'
