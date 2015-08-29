#!/bin/bash

########################################################
## Search for required commands and exit if not found ##
########################################################
commands=( convert pngquant rsvg-convert ar tar xz sed grep tr column cat sort find echo mkdir chmod rm cp mv ln pwd )

for i in "${commands[@]}"; do
    if ! which $i &> /dev/null; then
        missingcommands="$i $missingcommands"
    fi
done
if [[ ! -z $missingcommands ]]; then
    echo "The following commands are not found: $missingcommands"
    echo ""
    echo "Try installing the following packages:"
    echo "imagemagick pngquant binutils librsvg2-bin (Ubuntu)"
    echo "imagemagick pngquant binutils rsvg (Cygwin)"
    read -p "Press any key to exit..." -n1 -s
    exit
fi

##############################################
## Ask the user whether to build SNP or SRP ##
##############################################
if [[ -z $1 ]]; then
    echo "Which style are you going to build?"
    select choice in "Service Reference" "Service Name"; do
        case $choice in
            "Service Reference" ) style=srp; break;;
            "Service Name" ) style=snp; break;;
        esac
    done
else
    style=$1
fi

############################
## Setup folder locations ##
############################
location="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
buildsource="$location/build-source"
buildtools="$location/build-tools"
binaries="$location/build-output/binaries-$style"

if [[ -d /dev/shm ]] && [[ ! -f /.dockerinit ]]; then
    temp="/dev/shm/picons-tmp"
else
    temp="/tmp/picons-tmp"
fi

#############################################
## Check if previously chosen style exists ##
#############################################
if [[ $style = "srp" ]] || [[ $style = "snp" ]]; then
    for file in "$location/build-output/servicelist-"*"-$style" ; do
        if [[ ! -f $file ]]; then
            echo "No $style servicelist has been found! Exiting..."
            read -p "Press any key to exit..." -n1 -s
            exit
        fi
    done
else
    echo "You are using an unsupported style! Keep it tidy!"
fi

###########################################################
## Ask the user which resolution and background to build ##
###########################################################
if [[ -z $2 ]]; then
    for background in "$buildsource/backgrounds/"* ; do
        backgroundname=$(basename $background)
        backgrounds="$backgroundname $backgrounds"
    done

    echo "Which resolution would you like to build?"
    select choice in $backgrounds; do
        if [[ ! -z $choice ]]; then
            backgroundname=$choice; break
        fi
    done

    for backgroundcolor in "$buildsource/backgrounds/$backgroundname/"* ; do
        backgroundcolorname=$(basename ${backgroundcolor%.*})
        backgroundcolors="$backgroundcolorname $backgroundcolors"
    done

    echo "Which background would you like to build?"
    select choice in $backgroundcolors; do
        if [[ ! -z $choice ]]; then
            backgroundcolorname=$choice; break
        fi
    done
else
    if [[ $2 = "all" ]]; then
        backgroundname=""
        backgroundcolorname=""
    else
        backgroundname=$2
        if [[ -z $3 ]]; then
            for backgroundcolor in "$buildsource/backgrounds/$backgroundname/"* ; do
                backgroundcolorname=$(basename ${backgroundcolor%.*})
                backgroundcolors="$backgroundcolorname $backgroundcolors"
            done

            echo "Which background would you like to build?"
            select choice in $backgroundcolors; do
                if [[ ! -z $choice ]]; then
                    backgroundcolorname=$choice; break
                fi
            done
        else
            if [[ $3 = "all" ]]; then
                backgroundcolorname=""
            else
                backgroundcolorname=$3
            fi
        fi
    fi
fi

######################################################
## Cleanup previously created folders and re-create ##
######################################################
if [[ -d $temp ]]; then rm -rf "$temp"; fi
mkdir "$temp"

if [[ -d $binaries ]]; then rm -rf "$binaries"; fi
mkdir "$binaries"

##############################
## Determine version number ##
##############################
if [[ -d $location/.git ]] && which git &> /dev/null; then
    hash="$(git rev-parse --short HEAD)"
    version="$(date --date=@$(git show -s --format=%ct $hash) +'%Y-%m-%d--%H-%M-%S')"
    timestamp="$(date --date=@$(git show -s --format=%ct $hash) +'%Y%m%d%H%M.%S')"
else
    epoch="date +%s"
    version="$(date --date=@$($epoch) +'%Y-%m-%d--%H-%M-%S')"
    timestamp="$(date --date=@$($epoch) +'%Y%m%d%H%M.%S')"
fi

echo "$(date +'%H:%M:%S') - Version: $version"

#############################################
## Some basic checking of the source files ##
#############################################
chmod -R 755 "$buildtools/"*.sh

echo "$(date +'%H:%M:%S') - Checking index"
"$buildtools/check-index.sh" "$buildsource" "srp"
"$buildtools/check-index.sh" "$buildsource" "snp"

echo "$(date +'%H:%M:%S') - Checking logos"
"$buildtools/check-logos.sh" "$buildsource/tv"
"$buildtools/check-logos.sh" "$buildsource/radio"

#############################################################
## Create symlinks, copy required logos and convert to png ##
#############################################################
echo "$(date +'%H:%M:%S') - Creating symlinks and copying logos"
"$buildtools/create-symlinks+copy-logos.sh" "$location/build-output/servicelist-" "$temp/newbuildsource" "$buildsource" "$style"

echo "$(date +'%H:%M:%S') - Converting svg files"
for file in $(find "$temp/newbuildsource/logos" -type f -name '*.svg'); do
    rsvg-convert -w 400 -h 400 -a -f png -o ${file%.*}.png "$file"
    rm "$file"
done

####################################################################
## Start the actual conversion to picons and creation of packages ##
####################################################################
logocount=$(find "$temp/newbuildsource/logos/" -maxdepth 2 -type f | wc -l)

for background in "$buildsource/backgrounds/$backgroundname"* ; do

    backgroundname=$(basename $background)

    for backgroundcolor in "$buildsource/backgrounds/$backgroundname/$backgroundcolorname"*.png ; do

        currentlogo=""
        backgroundcolorname=$(basename ${backgroundcolor%.*})

        echo "$(date +'%H:%M:%S') -----------------------------------------------------------"
        echo "$(date +'%H:%M:%S') - Creating picons: $style.$backgroundname.$backgroundcolorname"

        mkdir -p "$temp/finalpicons/picon"

        for directory in "$temp/newbuildsource/logos/"* ; do
            if [[ -d $directory ]]; then
                directory=${directory##*/}
                for logo in "$temp/newbuildsource/logos/$directory/"*.png ; do
                    if [[ -f $logo ]]; then
                        ((currentlogo++))
                        echo -ne "           Converting logo: $currentlogo/$logocount"\\r

                        logoname=$(basename ${logo%.*})

                        if [[ ! -d $temp/finalpicons/picon/$directory ]]; then
                            mkdir -p "$temp/finalpicons/picon/$directory"
                        fi

                        if [[ $backgroundcolorname == *-white* ]]; then
                            if [[ -f $temp/newbuildsource/logos/$directory/white/$logoname.png ]]; then
                                logo="$temp/newbuildsource/logos/$directory/white/$logoname.png"
                            fi
                        fi

                        case "$backgroundname" in
                            "70x53")
                                if [[ $backgroundcolorname == *-nopadding ]]; then resize="70x53"; else resize="62x45"; fi
                                extent="70x53"
                                compress="pngquant -"
                                ;;
                            "100x60")
                                if [[ $backgroundcolorname == *-nopadding ]]; then resize="100x60"; else resize="86x46"; fi
                                extent="100x60"
                                compress="pngquant -"
                                ;;
                            "220x132")
                                if [[ $backgroundcolorname == *-nopadding ]]; then resize="220x132"; else resize="189x101"; fi
                                extent="220x132"
                                compress="pngquant -"
                                ;;
                            "400x170")
                                if [[ $backgroundcolorname == *-nopadding ]]; then resize="400x170"; else resize="369x157"; fi
                                extent="400x170"
                                compress="pngquant -"
                                ;;
                            "400x240")
                                if [[ $backgroundcolorname == *-nopadding ]]; then resize="400x240"; else resize="369x221"; fi
                                extent="400x240"
                                compress="pngquant -"
                                ;;
                            "kodi")
                                if [[ $backgroundcolorname == *-nopadding ]]; then resize="256x256"; else resize="226x226"; fi
                                extent="256x256"
                                compress="pngquant -"
                                ;;
                        esac

                        convert "$backgroundcolor" \( "$logo" -background none -bordercolor none -border 100 -trim -border 1% -resize $resize -gravity center -extent $extent +repage \) -layers merge - 2>> /dev/null | $compress > "$temp/finalpicons/picon/$directory/$logoname.png"

                    fi
                done
            fi
        done

        echo "$(date +'%H:%M:%S') - Creating binary packages: $style.$backgroundname.$backgroundcolorname"
        cp --no-dereference "$temp/newbuildsource/symlinks/"* "$temp/finalpicons/picon"

        packagename="$style.$backgroundname.${backgroundcolorname}_${version}"

        if [[ $backgroundname = "70x53" ]] || [[ $backgroundname = "100x60" ]] || [[ $backgroundname = "220x132" ]] || [[ $backgroundname = "400x240" ]] || [[ $backgroundname = "400x170" ]]; then
            mkdir "$temp/finalpicons/CONTROL" ; cat > "$temp/finalpicons/CONTROL/control" <<-EOF
				Package: enigma2-plugin-picons-$style.$backgroundname.$backgroundcolorname
				Version: $version
				Section: base
				Architecture: all
				Maintainer: http://picons.github.io
				Source: https://github.com/picons/picons-source
				Description: $style.$backgroundname.$backgroundcolorname
				OE: enigma2-plugin-picons-$style.$backgroundname.$backgroundcolorname
				HomePage: http://picons.github.io
				License: unknown
				Priority: optional
			EOF
            find "$temp/finalpicons" -exec touch --no-dereference -t "$timestamp" {} \;
            "$buildtools/ipkg-build.sh" -o root -g root "$temp/finalpicons" "$binaries" > /dev/null

            mv "$temp/finalpicons/picon" "$temp/finalpicons/$packagename"
            tar --dereference --owner=root --group=root -cf - --directory="$temp/finalpicons" "$packagename" --exclude="tv" --exclude="radio" | xz -9 --extreme --memlimit=40% > "$binaries/$packagename.tar.xz"
        fi

        if [[ $backgroundname = "kodi" ]]; then
            find "$temp/finalpicons" -exec touch --no-dereference -t "$timestamp" {} \;
            mv "$temp/finalpicons/picon" "$temp/finalpicons/$packagename"
            tar --owner=root --group=root -cf - --directory="$temp/finalpicons" "$packagename" | xz -9 --extreme --memlimit=40% > "$binaries/$packagename.tar.xz"
        fi

        find "$binaries" -exec touch -t "$timestamp" {} \;
        rm -rf "$temp/finalpicons"

    done
    backgroundcolorname=""
done

################################################################################
## Cleanup temporary files and let the user know the location of the packages ##
################################################################################
if [[ -d $temp ]]; then rm -rf "$temp"; fi

echo -e "\nThe binary packages are located in:\n$binaries\n"

##########################
## Ask the user to exit ##
##########################
if [[ -z $1 ]]; then
    read -p "Press any key to exit..." -n1 -s
fi
