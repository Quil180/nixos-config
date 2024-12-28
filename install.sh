# this script will install the nixos configuration files above, as well as home-manager.

# asking the user which phase of the install are you on?
echo "Which phase of the install are you in?"
read -p "1 or 2? " phase

if [ ${phase} == 1 ]; then
	# phase 1
	# asking the user what system you are installing onto...
	read -p "What system are you installing onto? " systemChoice
	read -p "What user is being installed? " userChoice

	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko system/${systemChoice}/disko.nix
	sudo nixos-install --no-root-passwd --root /mnt --flake /home/nixos/nixos-config#${systemChoice}
	cp -r ../nixos-config /mnt/home/${userChoice}/.dotfiles
	echo "Phase 1 complete, please reboot and start Phase 2..."

fi
if [ ${phase} == 2 ]; then
	# phase 2
	read -p "What user am I? " user
	sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
	sudo nix-channel --update
	sudo nix-shell '<home-manager>' -A install

	home-manager switch --flake ~/.dotfiles#${user}

	git remote set-url origin git@github.com:Quil180/nixos-config

	echo "please do the following command: source /home/${user}/.zshrc"
fi
