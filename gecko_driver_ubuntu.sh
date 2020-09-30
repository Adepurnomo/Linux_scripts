cd 
sudo apt install firefox python3-pip xvfb x11-utils --yes
sudo -H pip3 install bpython selenium
export DISPLAY=:2
Xvfb $DISPLAY -ac &
export GECKO_DRIVER_VERSION='v0.24.0'
wget https://github.com/mozilla/geckodriver/releases/download/$GECKO_DRIVER_VERSION/geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz 
tar -xvzf geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz
rm geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz
chmod +x geckodriver
sudo cp geckodriver /usr/local/bin/
