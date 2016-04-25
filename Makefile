.PHONY: install upgrade

install:
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

	sudo apt update
	sudo apt install -y openssh-server google-chrome-stable fbi unclutter xdotool

	curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
	sudo apt-get install -y nodejs

	sudo chmod +x ./kiosk/kiosk.sh
	sudo chmod +x ./updater/updater.sh
	sudo chmod +x ./scripts/generate_key.sh

	sudo mkdir -p /opt/sg_kiosk/
	sudo mkdir -p /opt/sg_kiosk/data/

	sudo cp ./socialgrab /etc/sudoers.d/

	sudo sh ./scripts/generate_key.sh

	sudo cp ./kiosk/kiosk.sh /opt/sg_kiosk/kiosk.sh
	sudo cp ./kiosk/upstart/kiosk.conf ~/.config/upstart/kiosk.conf

	sudo cp ./updater/updater.sh /opt/sg_kiosk/updater.sh
	sudo cp ./updater/upstart/updater.conf /etc/init/updater.conf

	sudo cp ./lightdm/lightdm.conf /etc/lightdm/lightdm.conf

	sudo cp ./VERSION /opt/sg_kiosk/data/VERSION

	sudo cp ./splash/sg_logo.png /opt/sg_kiosk/sg_logo.png

	rm -rf ~/Socialscreen
	git clone https://github.com/HejPetri/Socialscreen ~/Socialscreen
	rm -rf ~/Socialgrab-Kioskmode

upgrade:
	rm -rf ~/Socialscreen
	git clone https://github.com/HejPetri/Socialscreen ~/Socialscreen
	cd ~/Socialscreen
	make install
