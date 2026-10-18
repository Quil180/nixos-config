_: {
  flake.nixosModules.zerotier = _: {
    # The node identity; without it every boot is a new, unauthorised member.
    persist.directories = [ "/var/lib/zerotier-one" ];

    services.zerotierone = {
      enable = true;
      joinNetworks = [ "565799d8f611794d" ];
    };
  };
}
