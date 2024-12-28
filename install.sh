#!/bin/bash


# Генерация случайного пароля
# Запрос пароля
echo "Введите пароль:"
stty -echo  # Отключаем отображение символов
# Проверим, что нажатие клавиш действительно будет восприниматься
if ! read password; then
  echo "Ошибка ввода."
  exit 1
fi
stty echo  # Включаем отображение символов

echo # Печать пустой строки для улучшения визуального восприятия

# Важно: Здесь мы не выводим сам пароль, чтобы сохранить конфиденциальность
echo "Пароль введен."

# Обновление пакетов и установка apache2-utils
sudo apt-get update
sudo apt-get install -y apache2-utils

# Проверим, существует ли утилита htpasswd
if [ ! -f /usr/bin/htpasswd ]; then
    echo "htpasswd не установлена. Установите с помощью: sudo apt-get install apache2-utils"
    exit
fi


# Генерация bcrypt-хеша
hash=$(htpasswd -nbBC 10 "" "$PASSWORD" | tr -d ':\n')

# Вывод хеша
echo "Bcrypt хеш: $hash"

# Проверка успешной установки Docker Compose
#IP=$(curl -s ifconfig.me)
IP=$(ip addr show ens3 | grep -oP 'inet \K[\d.]+')


# Запуск контейнера с использованием сгенерированного хеша
docker run -d \
  --name=wg-easy \
  -e WG_HOST=$IP \
  -e PASSWORD_HASH="$hash" \
  -e WG_MTU=1280 \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy

echo -e "http://$IP:51821\n$PASSWORD" > wg-out.txt
