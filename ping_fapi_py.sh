#!/bin/bash

declare -a ips=(
    "13.225.164.218" "13.227.61.59" "143.204.127.42"
    "13.35.51.41" "99.84.58.138" "18.65.193.131"
    "18.65.176.132" "99.84.140.147" "13.225.173.96"
    "54.240.188.143" "13.35.55.41" "18.65.207.131"
    "143.204.79.125" "65.9.40.137" "99.84.137.147"
    "18.65.212.131"
)

declare -A results

# Упрощенный прогресс-бар (без tput)
function progress_bar {
    local current=$1
    local total=$2
    local width=50  # Фиксированная ширина прогресс-бара
    local filled=$((current*width/total))
    local empty=$((width-filled))
    printf "\rPing: [%${filled}s>%-${empty}s] %3d/%d" "" "" $current $total
}

# Пингуем все IP
for i in "${!ips[@]}"; do
    result=$(ping -c 1 -W 1 "${ips[$i]}" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
    results["${ips[$i]}"]=${result:-"timeout"}
    progress_bar $((i+1)) ${#ips[@]}
done

# Сортируем по ping
echo -e "\n\nРезультаты пинга:"
echo " № | IP-адрес            | Пинг (мс)"
echo "---|---------------------|-----------"

sorted_ips=$(for ip in "${!results[@]}"; do
    echo "$ip|${results[$ip]}"
done | sort -t'|' -k2n)

i=1
while IFS='|' read -r ip ping; do
    printf "%2d | %-19s | %s\n" "$i" "$ip" "$ping"
    ((i++))
done <<< "$sorted_ips"

echo -e "\nPing тест завершен"