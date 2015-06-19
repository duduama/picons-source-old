ABOUT
=====

All the full resolution channel logos and their link to the actual channel (=serviceref) are kept up2date in this repository. The end result are picons for Enigma2 tuners and Kodi mediacenter in combination with a compatible PVR backend.

BUILDING THE PICONS
===================

Copy your `enigma2` folder, your `tvheadend` folder or your `channels.conf` file to `./build-input` and execute the script `./1-build-servicelist.sh`. If all goes well, you'll end up with a new file located in your home folder similar to [servicelist_enigma2](https://gist.github.com/picons/c301a97d070797eb64b9). Now execute `./2-build-picons.sh`, this might take a while, have a look at the folder `~/picons-binaries` for the final result. By appending or removing the `.build` tag at the end of folders and files in `./build-source/backgrounds` you can control which background versions to build. By default everything is set to build.

On a default Ubuntu install, the following command `sudo apt-get install imagemagick pngnq librsvg2-bin binutils` should be sufficient, to get the required packages. Running the script on a Ubuntu Live system should be possible.

The repository can be downloaded [here](https://github.com/picons/picons-source/archive/master.zip).

CONTRIBUTING
============

So you would like to contribute? Have a look [here](https://github.com/picons/picons-source/blob/master/CONTRIBUTING.md).
