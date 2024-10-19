#!/bin/bash

set -e

gpu_temp_path="/sys/class/hwmon/hwmon1/temp2_input"
cpu_temp_path="/sys/class/hwmon/hwmon3/temp7_input"
pwm_paths=("/sys/class/hwmon/hwmon3/pwm1" "/sys/class/hwmon/hwmon3/pwm3")

max_pwm=255
min_pwm=50

enable_manual_fan_control() {
    for pwm_path in "${pwm_paths[@]}"
    do
        echo 1 > ${pwm_path}_enable
    done
}

set_fan_pwm() {
    local pwm=$1

    for pwm_path in "${pwm_paths[@]}"
    do
        echo "$pwm" > "${pwm_path}"
    done
}

get_gpu_temp() {
    cat "$gpu_temp_path"
}

get_cpu_temp() {
    cat "$cpu_temp_path"
}

calculate_pwm() {
    local max_temp=$1

    if [ "$max_temp" -le 50000 ]; then
        echo $min_pwm
    elif [ "$max_temp" -le 70000 ]; then
        echo $((min_pwm + (max_temp - 50000) * (130 - min_pwm) / 20000))
    elif [ "$max_temp" -le 80000 ]; then
        echo $((130 + (max_temp - 70000) * (max_pwm - 130) / 10000))
    else
        echo $max_pwm
    fi
}

tempcontrol() {
    enable_manual_fan_control

    while true; do
        gpu_temp=$(get_gpu_temp)
        cpu_temp=$(get_cpu_temp)

        if [ "$gpu_temp" -gt "$cpu_temp" ]; then
            max_temp=$gpu_temp
        else
            max_temp=$cpu_temp
        fi
        
        set_fan_pwm $(calculate_pwm "$max_temp")
    done
}

tempcontrol
