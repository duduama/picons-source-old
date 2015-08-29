#!/bin/bash

serviceref_list="$1"
build_location="$2"
source_location="$3"
style="$4"

if [[ -d $build_location ]]; then
    rm -rf "$build_location"
fi

mkdir -p "$build_location/symlinks"

cd "$build_location/symlinks"

####################################################################
## Create symlinks and copy logos for SNP & SRP using servicelist ##
####################################################################
if [[ $style = "snp" ]] || [[ $style = "srp" ]]; then
    cat "$serviceref_list"*"$style" | tr -d [:blank:] | tr -d [=*=] | while read line ; do
        IFS="|"
        line_data=($line)
        serviceref=${line_data[0]}
        link_srp=${line_data[2]}
        link_snp=${line_data[3]}

        IFS="="
        link_srp=($link_srp)
        logo_srp=${link_srp[1]}
        link_snp=($link_snp)
        logo_snp=${link_snp[1]}
        snpname=${link_snp[0]}

        if [[ ! $logo_srp = "--------" ]]; then
            ln -s -f "$logo_srp.png" "$serviceref.png"

            logoname=$(basename "$logo_srp")
            dir=$(dirname "$logo_srp")
            mkdir -p "$build_location/logos/$dir/white"
            find "$source_location/$dir/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/" \;
            find "$source_location/$dir/white/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/white/" \;
        fi

        if [[ $style = "snp" ]]; then
            if [[ ! $logo_snp = "--------" ]]; then
                ln -s -f "$logo_snp.png" "$snpname.png"

                logoname=$(basename "$logo_snp")
                dir=$(dirname "$logo_snp")
                mkdir -p "$build_location/logos/$dir/white"
                find "$source_location/$dir/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/" \;
                find "$source_location/$dir/white/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/white/" \;
            fi
        fi
    done
fi

#########################################################
## Create symlinks and copy logos using only snp-index ##
#########################################################
if [[ $style = "dirtysnp" ]]; then
    sed '1!G;h;$!d' "$source_location/snp-index" | while read line ; do
        IFS="="
        link_snp=($line)
        logo_snp=${link_snp[1]}
        snpname=${link_snp[0]}

        if [[ $snpname == *"_"* ]]; then
            if [[ $logo_snp == *"tv/"* ]]; then
                ln -s -f "$logo_snp.png" '1_0_1_'"$snpname"'_0_0_0'".png"
            fi
            if [[ $logo_snp == *"radio/"* ]]; then
                ln -s -f "$logo_snp.png" '1_0_2_'"$snpname"'_0_0_0'".png"
            fi
        else
            ln -s -f "$logo_snp.png" "$snpname.png"
        fi

        logoname=$(basename "$logo_snp")
        dir=$(dirname "$logo_snp")
        mkdir -p "$build_location/logos/$dir/white"
        find "$source_location/$dir/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/" \;
        find "$source_location/$dir/white/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/white/" \;
    done
fi

#########################################################
## Create symlinks and copy logos using only srp-index ##
#########################################################
if [[ $style = "dirtysrp" ]]; then
    sed '1!G;h;$!d' "$source_location/srp-index" | while read line ; do
        IFS="="
        link_srp=($line)
        logo_srp=${link_srp[1]}
        unique_id=${link_srp[0]}

        if [[ $logo_srp == *"tv/"* ]]; then
            ln -s -f "$logo_srp.png" '1_0_1_'"$unique_id"'_0_0_0'".png"
        fi
        if [[ $logo_srp == *"radio/"* ]]; then
            ln -s -f "$logo_srp.png" '1_0_2_'"$unique_id"'_0_0_0'".png"
        fi

        logoname=$(basename "$logo_srp")
        dir=$(dirname "$logo_srp")
        mkdir -p "$build_location/logos/$dir/white"
        find "$source_location/$dir/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/" \;
        find "$source_location/$dir/white/" -maxdepth 1 -type f -name "$logoname.*" -exec cp -n {} "$build_location/logos/$dir/white/" \;
    done
fi
