{pkgs, ...}:
{
	environment.packages = with pkgs; [
		kiwix
	];
}
