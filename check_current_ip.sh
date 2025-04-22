#!/bin/bash

# === НАСТРОЙКИ ===
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
SERVER_NAME="SERVERNAME"
API_URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
PING_CMD="/bin/ping"
LOG_FILE="/tmp/ping_debug.log"

# Очистка старого лога
> "$LOG_FILE"

echo "=== Запуск проверки IP ===" >> "$LOG_FILE"

# === Получаем текущий IP из /etc/hosts ===
current_ip=$(grep 'api\.binance\.com' /etc/hosts | head -n 1 | awk '{print $1}')
echo "Текущий IP: $current_ip" >> "$LOG_FILE"

if [[ -z "$current_ip" ]]; then
    echo "IP не найден в /etc/hosts" >> "$LOG_FILE"
    exit 1
fi

# Проверка доступности текущего IP
$PING_CMD -c 1 -W 3 "$current_ip" >> "$LOG_FILE" 2>&1
if [[ $? -eq 0 ]]; then
    echo "Текущий IP $current_ip доступен. Выход." >> "$LOG_FILE"
    exit 0
fi

echo "Текущий IP $current_ip НЕДОСТУПЕН, ищем замену..." >> "$LOG_FILE"

# === Массив IP ===
ips=("13.225.164.218" "13.227.61.59" "143.204.127.42" "13.35.51.41" "99.84.58.138"
     "18.65.193.131" "18.65.176.132" "99.84.140.147" "13.225.173.96" "54.240.188.143"
     "13.35.55.41" "18.65.207.131" "143.204.79.125" "65.9.40.137" "99.84.137.147"
     "18.65.212.131")

# Поиск первого доступного IP
for ip in "${ips[@]}"; do
    echo "Проверка IP: $ip" >> "$LOG_FILE"
    $PING_CMD -c 1 -W 3 "$ip" >> "$LOG_FILE" 2>&1
    if [[ $? -eq 0 ]]; then
        echo "✅ Найден доступный IP: $ip" >> "$LOG_FILE"

        # Обновление /etc/hosts
        sed -i '/api\.binance\.com/d' /etc/hosts
        sed -i '/fapi\.binance\.com/d' /etc/hosts
        echo "$ip api.binance.com" >> /etc/hosts
        echo "$ip fapi.binance.com" >> /etc/hosts

        # Уведомление в Telegram
        message="⚠️ $SERVERNAME ⚠️

🔁 API\FAPI \`$current_ip\` недоступен

➡️ Адрес API и FAPI автоматически изменён на: \`$ip\`

✅"
        curl -s -X POST "$API_URL" \
             -d chat_id="$CHAT_ID" \
             -d text="$message" \
             -d parse_mode="Markdown"

        exit 0
    fi
done

# Если не нашли доступный IP
echo "❌ Ни один IP не ответил." >> "$LOG_FILE"
curl -s -X POST "$API_URL" \
     -d chat_id="$CHAT_ID" \
     -d text=" ❌ $SERVERNAME ❌
Нет доступных IP-адресов для замены api.binance.com. Требуется ручное вмешательство."

exit 1
