#!/bin/bash

########################################################
## Search for required commands and exit if not found ##
########################################################
commands=( sed grep column cat sort find echo rm wc iconv awk printf pwd )

for i in "${commands[@]}"; do
    if ! which $i &> /dev/null; then
        missingcommands="$i $missingcommands"
    fi
done
if [[ ! -z $missingcommands ]]; then
    echo "The following commands are not found: $missingcommands"
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
            "Service Reference" ) style="srp"; break;;
            "Service Name" ) style="snp"; break;;
        esac
    done
else
    style=$1
fi

#####################################
## Setup file and folder locations ##
#####################################
location=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
index=$(<"$location/build-source/$style-index")

if [[ -d /dev/shm ]] && [[ ! -f /.dockerinit ]]; then
    temp="/dev/shm"
else
    temp="/tmp"
fi

##################################
## Enigma2 servicelist creation ##
##################################
if [[ -d $location/build-input/enigma2 ]]; then
    file="$location/build-output/servicelist-enigma2-$style"
    tempfile="$temp/$(echo $RANDOM)"
    lamedb=$(<"$location/build-input/enigma2/lamedb")
    channelcount=$(cat "$location/build-input/enigma2/"*bouquet.* | grep -o '#SERVICE .*:0:.*:.*:.*:.*:.*:0:0:0' | sort -u | wc -l)

    cat "$location/build-input/enigma2/"*bouquet.* | grep -o '#SERVICE .*:0:.*:.*:.*:.*:.*:0:0:0' | sed -e 's/#SERVICE //g' -e 's/.*/\U&\E/' -e 's/:/_/g' | sort -u | while read serviceref ; do
        ((currentline++))
        echo -ne "Enigma2: Converting channel: $currentline/$channelcount"\\r

        serviceref_id=$(sed -e 's/^[^_]*_0_[^_]*_//g' -e 's/_0_0_0$//g' <<< "$serviceref")
        unique_id=${serviceref_id%????}
        channelref=(${serviceref//_/ })
        channelname=$(grep -i -A1 "${channelref[3]}:.*${channelref[6]}:.*${channelref[4]}:.*${channelref[5]}:.*:.*" <<< "$lamedb" | sed -n "2p" | iconv -c -f utf-8 -t ascii | sed -e 's/^[ \t]*//' -e 's/|//g' -e 's/§//g')

        logo_srp=$(grep -i -m 1 "^$unique_id" <<< "$index" | sed -n -e 's/.*=//p')
        if [[ -z $logo_srp ]]; then logo_srp="--------"; fi

        if [[ $style = "snp" ]]; then
            snpname=$(sed -e 's/&/and/g' -e 's/*/star/g' -e 's/+/plus/g' -e 's/\(.*\)/\L\1/g' -e 's/[^a-z0-9]//g' <<< "$channelname")
            if [[ -z $snpname ]]; then snpname="--------"; fi
            logo_snp=$(grep -i -m 1 "^$snpname=" <<< "$index" | sed -n -e 's/.*=//p')
            if [[ -z $logo_snp ]]; then logo_snp="--------"; fi
            echo -e "$serviceref\t$channelname\t$serviceref_id=$logo_srp\t$snpname=$logo_snp" >> "$tempfile"
        else
            echo -e "$serviceref\t$channelname\t$serviceref_id=$logo_srp" >> "$tempfile"
        fi
    done

    sort -t $'\t' -k 2,2 "$tempfile" | sed -e 's/\t/§|/g' | column -t -s $'§' | sed -e 's/|/  |  /g' > "$file"
    rm "$tempfile"
    echo "Enigma2: Exported to $file"
else
    echo "Enigma2: $location/build-input/enigma2 not found"
fi

####################################
## TvHeadend servicelist creation ##
####################################
if [[ -d $location/build-input/tvheadend ]]; then
    file="$location/build-output/servicelist-tvheadend-$style"
    tempfile="$temp/$(echo $RANDOM)"
    channelcount=$(find "$location/build-input/tvheadend/channel/config/" -maxdepth 1 -type f | wc -l)

    for channelfile in "$location/build-input/tvheadend/channel/config/"* ; do
        ((currentline++))
        echo -ne "TvHeadend: Converting channel: $currentline/$channelcount"\\r

        serviceref=$(grep -o '1_0_.*_.*_.*_.*_.*_0_0_0' "$channelfile")
        serviceref_id=$(sed -e 's/^[^_]*_0_[^_]*_//g' -e 's/_0_0_0$//g' <<< "$serviceref")
        unique_id=${serviceref_id%????}
        tvhservice=$(grep -A1 'services' "$channelfile" | sed -n "2p" | sed -e 's/"//g' -e 's/,//g')
        channelname=$(grep 'svcname' $(find "$location/build-input/tvheadend" -type f -name $tvhservice) | sed -e 's/.*"svcname": "//g' -e 's/",//g' | iconv -c -f utf-8 -t ascii | sed -e 's/^[ \t]*//' -e 's/|//g' -e 's/§//g')

        logo_srp=$(grep -i -m 1 "^$unique_id" <<< "$index" | sed -n -e 's/.*=//p')
        if [[ -z $logo_srp ]]; then logo_srp="--------"; fi

        if [[ $style = "snp" ]]; then
            snpname=$(sed -e 's/&/and/g' -e 's/*/star/g' -e 's/+/plus/g' -e 's/\(.*\)/\L\1/g' -e 's/[^a-z0-9]//g' <<< "$channelname")
            if [[ -z $snpname ]]; then snpname="--------"; fi
            logo_snp=$(grep -i -m 1 "^$snpname=" <<< "$index" | sed -n -e 's/.*=//p')
            if [[ -z $logo_snp ]]; then logo_snp="--------"; fi
            echo -e "$serviceref\t$channelname\t$serviceref_id=$logo_srp\t$snpname=$logo_snp" >> "$tempfile"
        else
            echo -e "$serviceref\t$channelname\t$serviceref_id=$logo_srp" >> "$tempfile"
        fi
    done

    sort -t $'\t' -k 2,2 "$tempfile" | sed -e 's/\t/§|/g' | column -t -s $'§' | sed -e 's/|/  |  /g' > "$file"
    rm "$tempfile"
    echo "TvHeadend: Exported to $file"
else
    echo "TvHeadend: $location/build-input/tvheadend not found"
fi

##############################
## VDR servicelist creation ##
##############################
if [[ -f $location/build-input/channels.conf ]]; then
    file="$location/build-output/servicelist-vdr-$style"
    tempfile="$temp/$(echo $RANDOM)"
    channelcount=$(grep -o '.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:0' "$location/build-input/channels.conf" | sort -u | wc -l)

    grep -o '.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:.*:0' "$location/build-input/channels.conf" | sort -u | while read channel ; do
        ((currentline++))
        echo -ne "VDR: Converting channel: $currentline/$channelcount"\\r

        IFS=":"
        vdrchannel=($channel)
        IFS=";"

        sid=$(printf "%x\n" ${vdrchannel[9]})
        tid=$(printf "%x\n" ${vdrchannel[11]})
        nid=$(printf "%x\n" ${vdrchannel[10]})

        case ${vdrchannel[3]} in
            *"W") namespace=$(printf "%x\n" $(sed -e 's/S//' -e 's/W//' <<< "${vdrchannel[3]}" | awk '{printf "%.0f\n", 3600-($1*10)}'));;
            *"E") namespace=$(printf "%x\n" $(sed -e 's/S//' -e 's/E//' <<< "${vdrchannel[3]}" | awk '{printf "%.0f\n", $1*10}'));;
            "T") namespace="EEEE";;
            "C") namespace="FFFF";;
        esac
        case ${vdrchannel[5]} in
            "0") channeltype="2";;
            *"=2") channeltype="1";;
            *"=27") channeltype="19";;
        esac

        unique_id=$(sed -e 's/.*/\U&\E/' <<< "$sid"'_'"$tid"'_'"$nid"'_'"$namespace")
        serviceref='1_0_'"$channeltype"'_'"$unique_id"'0000_0_0_0'
        serviceref_id="$unique_id"'0000'
        channelname=(${vdrchannel[0]})
        channelname=$(iconv -c -f utf-8 -t ascii <<< "${channelname[0]}" | sed -e 's/^[ \t]*//' -e 's/|//g' -e 's/§//g')

        logo_srp=$(grep -i -m 1 "^$unique_id" <<< "$index" | sed -n -e 's/.*=//p')
        if [[ -z $logo_srp ]]; then logo_srp="--------"; fi

        if [[ $style = "snp" ]]; then
            snpname=$(sed -e 's/&/and/g' -e 's/*/star/g' -e 's/+/plus/g' -e 's/\(.*\)/\L\1/g' -e 's/[^a-z0-9]//g' <<< "$channelname")
            if [[ -z $snpname ]]; then snpname="--------"; fi
            logo_snp=$(grep -i -m 1 "^$snpname=" <<< "$index" | sed -n -e 's/.*=//p')
            if [[ -z $logo_snp ]]; then logo_snp="--------"; fi
            echo -e "$serviceref\t$channelname\t$serviceref_id=$logo_srp\t$snpname=$logo_snp" >> "$tempfile"
        else
            echo -e "$serviceref\t$channelname\t$serviceref_id=$logo_srp" >> "$tempfile"
        fi
    done

    sort -t $'\t' -k 2,2 "$tempfile" | sed -e 's/\t/§|/g' | column -t -s $'§' | sed -e 's/|/  |  /g' > "$file"
    rm "$tempfile"
    echo "VDR: Exported to $file"
else
    echo "VDR: $location/build-input/channels.conf not found"
fi

##########################
## Ask the user to exit ##
##########################
if [[ -z $1 ]]; then
    read -p "Press any key to exit..." -n1 -s
fi
