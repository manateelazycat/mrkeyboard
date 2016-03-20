#!/bin/sh

set -e

USAGE="Usage: `basename $0` (make|count|clean) [pkg] .."

[ $# -lt 1 ] && echo $USAGE && exit 1

DIR=$PWD/`dirname $0`
CMD=$1

shift

build_action () {
    PKG=$1
    echo == $PKG ==
	cd $DIR/app/$PKG
    case $CMD in
	clean) make clean
	    ;;
    count) cloc .
        ;;
	make) make
	    ;;
	*) echo "Unknown command: $CMD"; echo $USAGE; exit 1
	    ;;
    esac
    
    # End of command.
    echo
}

for pkg in ${*:-browser editor filemanager imageviewer musicplayer pdfviewer terminal videoplayer};
do
  build_action $pkg
done
