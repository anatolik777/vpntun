#!/bin/bash

# Убедитесь, что скрипт запущен с правами суперпользователя
if [ "$(id -u)" -ne 0 ]; then
    echo "Пожалуйста, запустите этот скрипт с правами суперпользователя."
    exit 1
fi

# Установка прав на выполнение для всех файлов в директории vpntun
chmod +x *

# Перемещение файлов в нужные директории
mv amn-via-socks.service /etc/systemd/system/
mv tun2socks /usr/local/bin
mv amn-via-socks.sh /root
cd ..

# Удаление директории vpntun
rm -r vpntun/

# Обновление конфигурации systemd
systemctl daemon-reload

# Включение и перезапуск сервиса
systemctl enable amn-via-socks
systemctl restart amn-via-socks

echo "Настройка завершена."
