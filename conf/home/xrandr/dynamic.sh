#!/bin/bash
# ~/.monitors.sh
# Dynamically set up connected monitors using xrandr

# Exit if xrandr is not available
command -v xrandr >/dev/null 2>&1 || { echo "xrandr not found"; exit 1; }

# Get connected monitors
connected=$(xrandr --query | grep " connected" | awk '{print $1}')

# Default primary monitor (first connected)
primary=$(echo "$connected" | head -n1)

# Arrange monitors: primary on left, others to the right
x_offset=0
for monitor in $connected; do
    # Default mode: preferred resolution
    mode=$(xrandr --query | grep "^$monitor" | grep -oP '\d+x\d+\+\d+\+\d+' | head -n1)
    # Fallback: use preferred resolution if xrandr can't parse
    mode=$(xrandr --query | grep "^$monitor" | grep -oP '\d+x\d+' | head -n1)
    
    if [ "$monitor" = "$primary" ]; then
        # Primary monitor
        xrandr --output "$monitor" --primary --mode "$mode" --pos 0x0
        x_offset=$(echo "$mode" | cut -d'x' -f1)  # width for next monitor
    else
        # Place to the right of the previous monitor
        xrandr --output "$monitor" --mode "$mode" --pos "${x_offset}x0"
        width=$(echo "$mode" | cut -d'x' -f1)
        x_offset=$((x_offset + width))
    fi
done
