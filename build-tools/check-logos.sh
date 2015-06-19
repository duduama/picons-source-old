#!/bin/bash

cd "$1"/white
for file in * ; do
    if [ ! -f "$1"/${file%.*}.* ]; then
        echo The following white logo has no black version: $file
    fi
done

cd "$1"
for file in *.svg ; do
    if [ -f ${file%.*}.png ]; then
        echo The following black logo has an obsolete png version: $file
    fi
done

cd "$1"/white
for file in *.svg ; do
    if [ -f ${file%.*}.png ]; then
        echo The following white logo has an obsolete png version: $file
    fi
done

cd "$1"
for file in *.svg ; do
    if [ -f "$1"/white/${file%.*}.png ]; then
        echo The following black logo is an svg, but has a white png: $file
    fi
done
