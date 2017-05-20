#Brostash = script to build an image for the raspberry pi

* Run `rpi_01_prepare.sh` to download the raspbian lite image. To increase the size of the image, run `IMAGE_SIZE=1 sh rpi_01_prepare.sh` to add 1Gb.

* Run `IMAGE_FILE=./raspbian.img CONFIG_DIR=./bropi sh rpi_02_build.sh` to build the image. This will download the dependency to build bro/pfring and push to image the install script.

* Finally write the img file to an sdcard and plug it in to your rpi. Start the pi and after the auto resizing is done, login and run `sh /opt/utils/bro_install`. Go get some coffee and wait for the install script to finish. After this you have a ready to go bro sensor you can plug in your home network.
