# this script will install the nixos configuration files above, as well as home-manager.

# installing git into the bare system.
echo "----------  Installing git onto the System  ----------"
sed -i 's/^{$/{\n programs.git.enable = true;/' /etc/nixos/configuration.nix
sudo nixos-rebuild switch

# cloning the configs from my personal github.
echo "----------  Cloning configs from GitHub  ----------"
cd
git clone https://github.com/quil180/nixos-config

# removing the old hardware-configuration thats in the github (if any), and copying the one for the current system.
echo "----------  Replacing hardware-configuration.nix from cloned configs  ----------"
cd nixos-config
rm hardware-configuration.nix
cp /etc/nixos/hardware-configuration.nix .

# building the configuration.nix from the github.
echo "----------  Swtiching to the new configuration.nix  ----------"
sudo nixos-rebuild switch --flake .#nixos-quil

# installing home-manager
echo "----------  Installing home-manager onto the system  ----------"
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
sudo nix-channel --update
sudo nix-shell '<home-manager>' -A install

# building the home-manager configs
echo "----------  Switching to the new home.nix  ----------"
home-manager switch --flake .#quil
