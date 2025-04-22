#!/bin/bash

ips=(
"13.225.164.218" "13.227.61.59" "143.204.127.42" "13.35.51.41" 
"99.84.58.138" "18.65.193.131" "18.65.176.132" "99.84.140.147"
"13.225.173.96" "54.240.188.143" "13.35.55.41" "18.65.207.131"
"143.204.79.125" "65.9.40.137" "99.84.137.147" "18.65.212.131"
)

declare -A results

progress_bar() {
    local current=$1 total=$2
    local cols=$(tput cols)
    local bar_size=$((cols-17))
    local filled=$((current*bar_size/total))
    printf "\rPing: [%-${bar_size}s] %d/%d" "$(printf '#%.0s' $(seq 1 $filled))" "$current" "$total"
}

for i in "${!ips[@]}"; do
    result=$(ping -c 1 -W 1 "${ips[$i]}" | awk -F'time=' '/time=/ {print $2}' | awk '{print $1}')
    results["${ips[$i]}"]=$result
    progress_bar "$((i+1))" "${#ips[@]}"
done

echo -e "\n\nРезультаты пинга:"
echo " № | IP-адрес            | Пинг (мс)"
echo "---|---------------------|-----------"

sorted_list=()
for ip in "${!results[@]}"; do
    sorted_list+=("$ip|${results[$ip]:-timeout}")
done

mapfile -t sorted_list < <(printf "%s\n" "${sorted_list[@]}" | sort -t'|' -k2n)

for i in "${!sorted_list[@]}"; do
    IFS='|' read -r ip time <<< "${sorted_list[$i]}"
    printf "%2d | %-19s | %s\n" "$((i+1))" "$ip" "$time"
done

echo -e "\nВыберите IP (1-${#sorted_list[@]}):"
read -rp "#? " selection

if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#sorted_list[@]} )); then
    echo "Ошибка выбора" >&2
    exit 1
fi

selected_ip=$(cut -d'|' -f1 <<< "${sorted_list[$((selection-1))]}")

sudo sed -i '/api\.binance\.com/d; /fapi\.binance\.com/d' /etc/hosts
echo "$selected_ip api.binance.com" | sudo tee -a /etc/hosts >/dev/null
echo "$selected_ip fapi.binance.com" | sudo tee -a /etc/hosts >/dev/null

echo -e "\nГотово. Проверка:"
grep -E "api\.binance\.com|fapi\.binance\.com" /etc/hosts
