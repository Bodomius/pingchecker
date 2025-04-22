#!/bin/bash

# Скачивание скрипта
echo "Скачивание скрипта..."
curl -o /root/check_current_ip.sh https://raw.githubusercontent.com/Bodomius/pingchecker/main/check_current_ip.sh

# Запрос данных у пользователя
read -p "Введите токен бота Telegram: " bot_token
read -p "Введите Chat ID: " chat_id
read -p "Введите название сервера (например, 🇯🇵 SHOCKHOSTING 🇯🇵): " server_name

# Замена placeholder'ов в скачанном скрипте
sed -i "s/YOUR_BOT_TOKEN/$bot_token/" /root/check_current_ip.sh
sed -i "s/YOUR_CHAT_ID/$chat_id/" /root/check_current_ip.sh
sed -i "s/SERVER_NAME/$server_name/" /root/check_current_ip.sh

# Делаем скрипт исполняемым
chmod +x /root/check_current_ip.sh

# Добавляем в cron
(crontab -l 2>/dev/null; echo "*/1 * * * * /bin/bash /root/check_current_ip.sh") | crontab -

echo "Установка завершена! Скрипт будет запускаться каждую минуту."