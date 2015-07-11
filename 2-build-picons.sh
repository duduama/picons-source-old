#!/bin/bash

#sudo apt-get install imagemagick pngnq librsvg2-bin binutils

version="$(date +'%Y-%m-%d--%H-%M-%S')"
timestamp="$(echo ${version//-/} | rev | cut -c 3- | rev).$(echo ${version//-/} | cut -c 13-)"

if [ -d "/dev/shm" ]; then
    temp="/dev/shm/picons-tmp"
else
    temp="/tmp/picons-tmp"
fi

location="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
buildsource="$location/build-source"
buildtools="$location/build-tools"
binaries="$HOME/picons-binaries"

if [ -d "$temp" ]; then rm -rf "$temp"; fi
mkdir "$temp"

if [ -d "$binaries" ]; then rm -rf "$binaries"; fi
mkdir "$binaries"

chmod -R 755 "$buildtools/"*.sh

echo "$(date +'%H:%M:%S') - Version: $version"

echo "$(date +'%H:%M:%S') - Checking logos"
"$buildtools/check-logos.sh" "$buildsource/tv"
"$buildtools/check-logos.sh" "$buildsource/radio"

echo "$(date +'%H:%M:%S') - Creating symlinks and copying logos"
"$buildtools/create-symlinks+copy-logos.sh" "$HOME/servicelist_" "$temp/newbuildsource" "$buildsource"

echo "$(date +'%H:%M:%S') - Converting svg files"
for file in $(find "$temp/newbuildsource/logos" -type f -name '*.svg'); do
    rsvg-convert -w 400 -h 400 -a -f png -o ${file%.*}.png "$file"
    rm "$file"
done

for background in "$buildsource/backgrounds/"*.build ; do

    backgroundname=$(basename ${background%.*})

    for backgroundcolor in "$buildsource/backgrounds/$backgroundname.build/"*.build ; do

        backgroundcolorname=$(basename ${backgroundcolor%.*.*})

        echo "$(date +'%H:%M:%S') -----------------------------------------------------------"
        echo "$(date +'%H:%M:%S') - Creating picons: $backgroundname.$backgroundcolorname"

        mkdir -p "$temp/finalpicons/picon"

        for directory in "$temp/newbuildsource/logos/"* ; do
            if [ -d "$directory" ]; then
                directory=${directory##*/}
                for logo in "$temp/newbuildsource/logos/$directory/"*.png ; do
                    if [ -f "$logo" ]; then
                        logoname=$(basename ${logo%.*})

                        if ! [ -d "$temp/finalpicons/picon/$directory" ]; then
                            mkdir -p "$temp/finalpicons/picon/$directory"
                        fi

                        if [[ "$backgroundcolorname" == *-white* ]]; then
                            if [ -f "$temp/newbuildsource/logos/$directory/white/$logoname.png" ]; then
                                logo="$temp/newbuildsource/logos/$directory/white/$logoname.png"
                            fi
                        fi

                        case "$backgroundname" in
                            "70x53")
                                if [[ "$backgroundcolorname" == *-nopadding ]]; then resize="70x53"; else resize="62x45"; fi
                                extent="70x53"
                                compress="pngnq -g 2.2 -s 1"
                                ;;
                            "100x60")
                                if [[ "$backgroundcolorname" == *-nopadding ]]; then resize="100x60"; else resize="86x46"; fi
                                extent="100x60"
                                compress="pngnq -g 2.2 -s 1"
                                ;;
                            "220x132")
                                if [[ "$backgroundcolorname" == *-nopadding ]]; then resize="220x132"; else resize="189x101"; fi
                                extent="220x132"
                                compress="pngnq -g 2.2 -s 1"
                                ;;
                            "400x170")
                                if [[ "$backgroundcolorname" == *-nopadding ]]; then resize="400x170"; else resize="369x157"; fi
                                extent="400x170"
                                compress="pngnq -g 2.2 -s 1"
                                ;;
                            "400x240")
                                if [[ "$backgroundcolorname" == *-nopadding ]]; then resize="400x240"; else resize="369x221"; fi
                                extent="400x240"
                                compress="pngnq -g 2.2 -s 1"
                                ;;
                            "kodi")
                                if [[ "$backgroundcolorname" == *-nopadding ]]; then resize="256x256"; else resize="226x226"; fi
                                extent="256x256"
                                compress="cat"
                                ;;
                        esac

                        convert "$backgroundcolor" \( "$logo" -background none -bordercolor none -border 100 -trim -resize $resize -gravity center -extent $extent +repage \) -layers merge - 2>> /dev/null | $compress > "$temp/finalpicons/picon/$directory/$logoname.png"

                    fi
                done
            fi
        done

        echo "$(date +'%H:%M:%S') - Creating binary packages: $backgroundname.$backgroundcolorname"
        cp --no-dereference "$temp/newbuildsource/symlinks/"* "$temp/finalpicons/picon"

        packagename="$backgroundname.${backgroundcolorname}_${version}"

        if [ "$backgroundname" = "70x53" ] || [ "$backgroundname" = "100x60" ] || [ "$backgroundname" = "220x132" ] || [ "$backgroundname" = "400x240" ]; then
            mkdir "$temp/finalpicons/CONTROL" ; cat > "$temp/finalpicons/CONTROL/control" <<-EOF
				Package: enigma2-plugin-picons-$backgroundname.$backgroundcolorname
				Version: $version
				Section: base
				Architecture: all
				Maintainer: http://picons.github.io
				Source: https://github.com/picons/picons-source
				Description: $backgroundname Picons ($backgroundcolorname)
				OE: enigma2-plugin-picons-$backgroundname.$backgroundcolorname
				HomePage: http://picons.github.io
				License: unknown
				Priority: optional
			EOF
            find "$temp/finalpicons" -exec touch --no-dereference -t "$timestamp" {} \;
            fakeroot -- "$buildtools/ipkg-build.sh" -o root -g root "$temp/finalpicons" "$binaries" > /dev/null

            mv "$temp/finalpicons/picon" "$temp/finalpicons/$packagename"
            fakeroot -- tar --dereference --owner=root --group=root -cf - --directory="$temp/finalpicons" "$packagename" --exclude="tv" --exclude="radio" | xz -9 --extreme --memlimit=40% > "$binaries/$packagename.tar.xz"
        fi

        if [ "$backgroundname" = "kodi" ]; then
            find "$temp/finalpicons" -exec touch --no-dereference -t "$timestamp" {} \;
            mv "$temp/finalpicons/picon" "$temp/finalpicons/$packagename"
            fakeroot -- tar --owner=root --group=root -cf - --directory="$temp/finalpicons" "$packagename" | xz -9 --extreme --memlimit=40% > "$binaries/$packagename.tar.xz"
        fi

        find "$binaries" -exec touch -t "$timestamp" {} \;
        rm -rf "$temp/finalpicons"

    done

done

if [ -d "$temp" ]; then rm -rf "$temp"; fi

echo -e "\nThe binary packages are located in:\n$binaries\n"
read -p "Press any key to exit..." -n1 -s
