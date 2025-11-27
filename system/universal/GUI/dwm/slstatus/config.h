/* See LICENSE file for copyright and license details. */

/* interval between updates (in ms) */
const unsigned int interval = 1000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "n/a";

/* maximum output string length */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function format          argument */
	{ cpu_perc,    "  %s%% ",   NULL },
	{ ram_perc,    "  %s%% ",   NULL },
    { run_command, "  %s°C ", "cat /sys/class/thermal/thermal_zone0/temp | awk '{print int($1/1000)}'" },
    { run_command, "  %s ", "pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}'" },
    { run_command, "  %s%% ", "brightnessctl -m | cut -d, -f4 | tr -d %" },
	{ battery_perc, "  %s%% ", "BAT0" },
	{ datetime,    "  %s ",    "%I:%M %p" },
};
