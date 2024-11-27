# How do I install this config?
```
curl -LJ0 https://raw.githubusercontent.com/Quil180/nixos-config/refs/heads/install.sh > install.sh
chmod +x install.sh
./install.sh
```

# Afterwards I need to setup an ssh key for github?
```
cd ~/.ssh
ssh-keygen -t rsa -b 4096 -C "email@email.com"
cat id_rsa.pub
```
Copy the contents pasted out, then put it into your github :)
