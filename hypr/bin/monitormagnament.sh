#!/usr/bin/env bash
CONFIG_FILE="$HOME/.config/hypr/display_config.txt"

# Monitör isimlerini otomatik bul
LAPTOP=$(hyprctl monitors -j | jq -r '.[] | select(.name | test("^eDP")).name' | head -n1)
MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.name | test("^(HDMI|DP|USB-C)")).name' | head -n1)

# fallback
LAPTOP=${LAPTOP:-"eDP-2"}
MONITOR=${MONITOR:-"HDMI-A-1"}

RES_LAPTOP="1920x1080@144"
RES_MONITOR="1920x1080@165"

mkdir -p "$(dirname "$CONFIG_FILE")"

if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<EOF
MODE=Extend
$LAPTOP,$RES_LAPTOP,0x0,1,transform,0
$MONITOR,$RES_MONITOR,1920x0,1,transform,0
EOF
fi

restart_waybar() {
    pkill waybar
    sleep 0.5
    if [[ "$1" == "extend" ]]; then
        waybar &
        waybar -c ~/.config/waybar/extenalconf.jsonc &
    else
        waybar &
    fi
}

apply_config() {
    while IFS= read -r line; do
        [[ "$line" == MODE=* ]] && continue  # MODE satırını atla
        if [[ "$line" == *"disable"* ]]; then
            hyprctl keyword monitor "$(echo "$line" | cut -d',' -f1),disable"
        else
            hyprctl keyword monitor "$line"
        fi
    done < "$CONFIG_FILE"
}

calc_position_for_rotation() {
    local rot=$1
    local pos=$2
    local W=1920
    local H=1080
    local X=0
    local Y=0

    case "$pos" in
        Right)
            case "$rot" in
                3|7) X=$W; Y=$((-960)) ;; 
                *)   X=$W; Y=0 ;;
            esac
            ;;
        Left)   X=$((-W)); Y=0 ;;
        Above)  X=0; Y=$((-H)) ;;
        Below)  X=0; Y=$H ;;
        Disable) echo "disable"; return ;;
        *)      X=0; Y=0 ;;
    esac

    echo "${X}x${Y}"
}

update_config() {
    name=$1
    field=$2
    value=$3
    tmp=$(mktemp)

    while IFS= read -r line; do
        if [[ "$line" == "$name,"* && "$line" != *"disable"* ]]; then
            IFS=',' read -r m res pos scale _ rot <<< "$line"
            if [[ "$field" == "position" ]]; then
                pos="$value"
            elif [[ "$field" == "transform" ]]; then
                rot="$value"
                pos_line=$(grep "^$name," "$CONFIG_FILE" | grep -v disable)
                old_pos=$(echo "$pos_line" | cut -d',' -f3)
                x_val=${old_pos%x*}
                y_val=${old_pos#*x}
                if (( x_val > 0 )); then pos_type="Right"
                elif (( x_val < 0 )); then pos_type="Left"
                elif (( y_val > 0 )); then pos_type="Below"
                elif (( y_val < 0 )); then pos_type="Above"
                else pos_type="Right"
                fi
                pos=$(calc_position_for_rotation "$rot" "$pos_type")
            fi
            echo "$m,$res,$pos,$scale,transform,$rot" >> "$tmp"
        else
            echo "$line" >> "$tmp"
        fi
    done < "$CONFIG_FILE"

    mv "$tmp" "$CONFIG_FILE"
}

### --- Ana Menü ---
action=$(printf "Display Mode\nRotate\nSet Position" | rofi -dmenu -p "Select Action:")
[[ -z "$action" ]] && exit

### --- Display Mode ---
if [[ "$action" == "Display Mode" ]]; then
    mode=$(printf "Laptop Only\nMonitor Only\nExtend\nMirror" | rofi -dmenu -p "Display Mode:")
    [[ -z "$mode" ]] && exit

    case "$mode" in
        "Laptop Only")
            echo "MODE=Laptop Only" > "$CONFIG_FILE"
            echo "$LAPTOP,$RES_LAPTOP,0x0,1,transform,0" >> "$CONFIG_FILE"
            echo "$MONITOR,disable" >> "$CONFIG_FILE"
            restart_waybar "laptop"
            ;;
        "Monitor Only")
            echo "MODE=Monitor Only" > "$CONFIG_FILE"
            echo "$LAPTOP,disable" >> "$CONFIG_FILE"
            echo "$MONITOR,$RES_MONITOR,0x0,1,transform,0" >> "$CONFIG_FILE"
            restart_waybar "extend"
            ;;
        "Extend")
            echo "MODE=Extend" > "$CONFIG_FILE"
            echo "$LAPTOP,$RES_LAPTOP,0x0,1,transform,0" >> "$CONFIG_FILE"
            echo "$MONITOR,$RES_MONITOR,-1920x0,1,transform,0" >> "$CONFIG_FILE"
            restart_waybar "extend"
            ;;
            "Mirror")
            echo "MODE=Extend" > "$CONFIG_FILE"
            echo "$LAPTOP,$RES_LAPTOP,0x0,1,transform,0" >> "$CONFIG_FILE"
            echo "$MONITOR,$RES_MONITOR,-1920x0,1,transform,0,mirror,$LAPTOP" >> "$CONFIG_FILE"
            restart_waybar "laptop"
            ;;
    esac
    apply_config

### --- Rotate ---
elif [[ "$action" == "Rotate" ]]; then
    rot=$(printf "0 - Normal\n1 - 90°\n2 - 180°\n3 - 270°\n4 - FlipH\n5 - FlipH+90\n6 - FlipH+180\n7 - FlipH+270" | rofi -dmenu -p "Select Rotation:")
    [[ -z "$rot" ]] && exit
    rot_num=$(echo "$rot" | cut -d' ' -f1)
    update_config "$MONITOR" transform "$rot_num"
    apply_config

### --- Set Position ---
elif [[ "$action" == "Set Position" ]]; then
    pos=$(printf "Right\nLeft\nAbove\nBelow\nDisable" | rofi -dmenu -p "Monitor Position:")
    [[ -z "$pos" ]] && exit
    rot=$(grep "$MONITOR" "$CONFIG_FILE" | grep -v disable | cut -d',' -f6)

    if [[ "$pos" == "Disable" ]]; then
        tmp=$(mktemp)
        grep -v "^$MONITOR," "$CONFIG_FILE" > "$tmp"
        echo "$MONITOR,disable" >> "$tmp"
        mv "$tmp" "$CONFIG_FILE"
    else
        new_pos=$(calc_position_for_rotation "$rot" "$pos")
        update_config "$MONITOR" position "$new_pos"
    fi

    apply_config
fi
