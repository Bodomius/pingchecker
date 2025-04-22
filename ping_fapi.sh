 #!/bin/bash

declare -a ips=("13.225.164.218" "13.227.61.59" "143.204.127.42" "13.35.51.41" "99.84.58.138" "18.65.193.131" "18.65.176.132" "99.84.140.147" "13.225.173.96" "54.240.188.143" "13.35.55.41" "18.65.207.131" "143.204.79.125" "65.9.40.137" "99.84.137.147" "18.65.212.131")

declare -A results

function progress_bar {
    local current=$1
    local total=$2
    local cols=$(tput cols)
    let bar_size=$cols-17
    local filled=$((current*bar_size/total))
    local empty=$((bar_size-filled))
    printf "\rPing: [%${filled}s>%-${empty}s] %3d/%d" "" "" $current $total
}

# Пингуем IP
for i in "${!ips[@]}"; do
    result=$(ping -c 1 -W 1 "${ips[$i]}" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
    results["${ips[$i]}"]=$result
    progress_bar $((i+1)) ${#ips[@]}
done

echo -e "\n\nРезультаты пинга:"
echo " № | IP-адрес            | Пинг (мс)"
echo "---|---------------------|-----------"

sorted_list=()
for ip in "${!results[@]}"; do
    ping_time="${results[$ip]}"
    sorted_list+=("$ip|${ping_time:-timeout}")
done

IFS=$'\n' sorted_list=($(printf "%s\n" "${sorted_list[@]}" | sort -t'|' -k2n))

for i in "${!sorted_list[@]}"; do
    ip=$(echo "${sorted_list[$i]}" | cut -d'|' -f1)
    time=$(echo "${sorted_list[$i]}" | cut -d'|' -f2)
    printf "%2d | %-19s | %s\n" $((i+1)) "$ip" "${time:-timeout}"
done

# Ручной выбор IP
echo -e "\nВыберите IP-адрес, который будет прописан в /etc/hosts для api и fapi:"
read -rp "#? " selection

if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#sorted_list[@]} )); then
    echo "❌ Неверный выбор. Завершение."
    exit 1
fi

selected_ip=$(echo "${sorted_list[$((selection - 1))]}" | cut -d'|' -f1)

# Обновление /etc/hosts
sudo sed -i '/api\.binance\.com/d' /etc/hosts
sudo sed -i '/fapi\.binance\.com/d' /etc/hosts

echo "$selected_ip api.binance.com" | sudo tee -a /etc/hosts > /dev/null
echo "$selected_ip fapi.binance.com" | sudo tee -a /etc/hosts > /dev/null

echo -e "\n✔️ Готово. Текущие записи в /etc/hosts:"
grep -E "api\.binance\.com|fapi\.binance\.com" /etc/hosts
