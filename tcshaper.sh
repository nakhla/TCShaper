#!/bin/bash

# Validate input arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <interface> <download_speed upload_speed | clear>"
    echo "Example to limit speed: $0 eth0 8192 2048"
    echo "Example to clear limits: $0 eth0 clear"
    exit 1
fi

INTERFACE=$1
COMMAND=$2
IFB="ifb0"

# Function to calculate compensated rate
compensate_rate() {
    local RATE=$1
    local COMPENSATED=$(echo "$RATE * 1.05" | bc)
    echo "${COMPENSATED%.*}"
}

# Function to set up the IFB interface
setup_ifb() {
    if ! ip link show "$IFB" > /dev/null 2>&1; then
        echo "Creating IFB device..."
        modprobe ifb
        ip link add "$IFB" type ifb
        ip link set "$IFB" up
    fi
}

# Function to clear all qdisc rules and remove IFB
clear_qdisc() {
    echo "Clearing all qdisc rules on $INTERFACE and $IFB..."
    tc qdisc del dev "$INTERFACE" root 2>/dev/null
    tc qdisc del dev "$INTERFACE" ingress 2>/dev/null
    tc qdisc del dev "$IFB" root 2>/dev/null

    if ip link show "$IFB" > /dev/null 2>&1; then
        echo "Removing IFB device..."
        ip link set "$IFB" down
        ip link delete "$IFB"
    fi

    echo "All limits cleared and IFB device removed."
}

# Function to apply bandwidth limits
apply_limits() {
    DOWNLOAD_SPEED=$(compensate_rate "$1")
    UPLOAD_SPEED=$(compensate_rate "$2")
    BURST_SIZE="64kbit"

    echo "Applying bandwidth limits with overhead compensation:"
    echo "  Download: ${DOWNLOAD_SPEED}kbit (compensated)"
    echo "  Upload:   ${UPLOAD_SPEED}kbit (compensated)"

    clear_qdisc

    # Set up the IFB device for download shaping
    setup_ifb
    tc qdisc add dev "$INTERFACE" handle ffff: ingress
    tc filter add dev "$INTERFACE" parent ffff: protocol ip u32 match ip src 0.0.0.0/0 action mirred egress redirect dev "$IFB"

    # Configure download limits on the IFB device
    tc qdisc add dev "$IFB" root handle 1: htb default 10
    tc class add dev "$IFB" parent 1: classid 1:1 htb rate "${DOWNLOAD_SPEED}kbit" burst "$BURST_SIZE"
    tc class add dev "$IFB" parent 1:1 classid 1:10 htb rate "${DOWNLOAD_SPEED}kbit" burst "$BURST_SIZE"

    # Configure upload limits on the main interface
    tc qdisc add dev "$INTERFACE" root handle 1: htb default 10
    tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate "${UPLOAD_SPEED}kbit" burst "$BURST_SIZE"
    tc class add dev "$INTERFACE" parent 1:1 classid 1:10 htb rate "${UPLOAD_SPEED}kbit" burst "$BURST_SIZE"

    echo "Bandwidth limits applied successfully!"
}

# Main logic
if [ "$COMMAND" == "clear" ]; then
    clear_qdisc
elif [ $# -eq 3 ]; then
    DOWNLOAD=$2
    UPLOAD=$3
    apply_limits "$DOWNLOAD" "$UPLOAD"
else
    echo "Invalid arguments. Use 'clear' or provide download and upload speeds."
    exit 1
fi
