# How do I install this config?
```
curl -LJ0 https://raw.githubusercontent.com/Quil180/nixos-config/refs/heads/install.sh > install.sh
chmod +x install.sh
./install.sh
```

After which, choose phase 1 if still on the ISO installer, and phase 2 if on the local ssd/hard drive.

# Afterwards I need to setup an ssh key for github?
```
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -C "email@email.com"
cat id_rsa.pub
```
Copy the contents pasted out, then put it into your github :)
# Installing extra software (non-declaratively)
## Vivado/Xilinx
Install the Xilinx\_Unified\_XXXX.X\_XXXX\_XXXX\_Lin64.bin installer from the AMD website and chmod +x it.
```
nix --option extra-experimental-features 'nix-command flakes' run gitlab:doronbehar/nix-xilinx#xilinx-shell
```
After this follow the prompts and put the vivado software in a user-writable directory (like Documents), and then create the following folder, `~/.config/xilinx/nix.sh`:
```
INSTALL_DIR=$HOME/downloads/software/xilinx
# The directory in which there's a /bin/ directory for each product, for example:
# $HOME/downloads/software/xilinx/Vivado/YEAR.VERSION/bin
VERSION=YEAR/VERSION
```
Now, to add the .desktop to the system so it's recognized without having to open the file folder, do, reference the following github, `https://gitlab.com/doronbehar/nix-xilinx/-/tree/master?ref_type=heads#user-content-for-nixos-users-with-a-flakes-setup`


