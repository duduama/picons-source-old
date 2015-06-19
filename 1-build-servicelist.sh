#!/bin/bash

location=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ -d "/dev/shm" ]; then
    temp="/dev/shm"
else
    temp="/tmp"
fi

#Enigma2
if [ -d "$location/build-input/enigma2" ]; then
    echo "Enigma2: Converting channellist..."

    file="$HOME/servicelist_enigma2"
    tempfile="$temp/$(echo $RANDOM)"

    cat "$location/build-input/enigma2/"*bouquet.* | grep -o '#SERVICE .*:0:.*:.*:.*:.*:.*:0:0:0' | sed -e 's/#SERVICE //g' -e 's/.*/\U&\E/' -e 's/:/_/g' | sort | uniq | while read serviceref ; do
        unique_id=$(echo "$serviceref" | sed -n -e 's/^[^_]*_0_[^_]*_//p' | sed -n -e 's/...._0_0_0$//p')
        logo=$(cat "$location/build-source/srindex" | grep -i -m 1 "$unique_id" | sed -n -e 's/.*=//p')
        channelref=(${serviceref//_/ })
        channelname=$(cat "$location/build-input/enigma2/lamedb" | grep -i -A1 "${channelref[3]}:.*${channelref[6]}:.*${channelref[4]}:.*${channelref[5]}:.*:.*" | sed -n "2p" | iconv -c -f utf-8 -t ascii | sed -e 's/^[ \t]*//')
        if [ -z "$logo" ]; then
            logo="--------"
        fi
        echo -e "$serviceref\t$logo\t$channelname" >> "$tempfile"
        currentline=$((currentline+1))
        echo -ne "Channels found: $currentline"\\r
    done

    cat "$tempfile" | sort -t $'\t' -k 3,3 | uniq | column -t -s $'\t' > "$file"
    rm "$tempfile"
    echo "Enigma2: Exported to $file"
else
    echo "Enigma2: Folder ./build-input/enigma2 not found"
fi

#TvHeadend
if [ -d "$location/build-input/tvheadend" ]; then
    echo "TvHeadend: Converting channellist..."

    file="$HOME/servicelist_tvheadend"
    tempfile="$temp/$(echo $RANDOM)"

    for channelfile in "$location/build-input/tvheadend/channel/config/"* ; do
        serviceref=$(cat $channelfile | grep -o '1_0_.*_.*_.*_.*_.*_0_0_0')
        unique_id=$(echo "$serviceref" | sed -n -e 's/^1_0_[^_]*_//p' | sed -n -e 's/...._0_0_0$//p')
        logo=$(cat "$location/build-source/srindex" | grep -i -m 1 "$unique_id" | sed -n -e 's/.*=//p')
        tvhservice=$(cat $channelfile | grep -A1 'services' | sed -n "2p" | sed -e 's/"//g' -e 's/,//g')
        channelname=$(cat $(find "$location/build-input/tvheadend" -type f -name $tvhservice) | grep 'svcname' | sed -e 's/.*"svcname": "//g' -e 's/",//g' | iconv -c -f utf-8 -t ascii | sed -e 's/^[ \t]*//')
        if [ -z "$logo" ]; then
            logo="--------"
        fi
        echo -e "$serviceref\t$logo\t$channelname" >> "$tempfile"
        currentline=$((currentline+1))
        echo -ne "Channels found: $currentline"\\r
    done

    cat "$tempfile" | sort -t $'\t' -k 3,3 | uniq | column -t -s $'\t' > "$file"
    rm "$tempfile"
    echo "TvHeadend: Exported to $file"
else
    echo "TvHeadend: Folder ./build-input/tvheadend not found"
fi

#VDR
if [ -f "$location/build-input/channels.conf" ]; then
    echo "VDR: Converting channellist..."

    file="$HOME/servicelist_vdr"
    tempfile="$temp/$(echo $RANDOM)"

    cat "$location/build-input/channels.conf" | grep -o '.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:0' | sort | uniq | while read channel ; do
        IFS=":"
        vdrchannel=($channel)
        IFS=";"
        channelname=(${vdrchannel[0]})
        channelname=$(echo ${channelname[0]} | iconv -c -f utf-8 -t ascii | sed -e 's/^[ \t]*//')

        sid=$(printf "%x\n" ${vdrchannel[9]})
        tid=$(printf "%x\n" ${vdrchannel[11]})
        nid=$(printf "%x\n" ${vdrchannel[10]})

        case ${vdrchannel[3]} in
            *"W") namespace=$(printf "%x\n" $(echo "${vdrchannel[3]}" | sed -e 's/S//' -e 's/W//' | awk '{printf "%.0f\n", 3600-($1*10)}'));;
            *"E") namespace=$(printf "%x\n" $(echo "${vdrchannel[3]}" | sed -e 's/S//' -e 's/E//' | awk '{printf "%.0f\n", $1*10}'));;
            "T") namespace="EEEE";;
            "C") namespace="FFFF";;
        esac
        case ${vdrchannel[5]} in
            "0") channeltype="2";;
            *"=2") channeltype="1";;
            *"=27") channeltype="19";;
        esac

        unique_id=$(echo "$sid"'_'"$tid"'_'"$nid"'_'"$namespace" | sed -e 's/.*/\U&\E/')
        logo=$(cat "$location/build-source/srindex" | grep -i -m 1 "$unique_id" | sed -n -e 's/.*=//p')
        if [ -z "$logo" ]; then
            logo="--------"
        fi
        echo -e '1_0_'"$channeltype"'_'"$unique_id"'0000_0_0_0'"\t$logo\t$channelname" >> "$tempfile"
        currentline=$((currentline+1))
        echo -ne "Channels found: $currentline"\\r
    done

    cat "$tempfile" | sort -t $'\t' -k 3,3 | uniq | column -t -s $'\t' > "$file"
    rm "$tempfile"
    echo "VDR: Exported to $file"
else
    echo "VDR: File ./build-input/channels.conf not found"
fi

read -p "Press any key to exit..." -n1 -s
