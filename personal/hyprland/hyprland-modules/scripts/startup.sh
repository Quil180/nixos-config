#!/usr/bin/env bash

swww-daemon &
swww img ~/nixos-config/wallpapers/eepy_myne.png &

nm-applet --indicator &

asusctl -c 80 &

wl-paste --watch cliphist store &

dunst
