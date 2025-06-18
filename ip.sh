#!/bin/bash

# Запрашиваем у пользователя новое значение
read -p "Введите новое значение для SOCKS_PROXY: " NEW_VALUE

# Устанавливаем путь к файлу
FILE="amn-via-socks.sh"

# Проверяем, что файл существует
if [ ! -f "$FILE" ]; then
    echo "Файл $FILE не найден."
    exit 1
fi

# Замена части строки номер 10 от SOCKS_PROXY="socks5:// до "
sed -i '10s|SOCKS_PROXY="socks5://.*"|SOCKS_PROXY="socks5://'$NEW_VALUE'"|' "$FILE"
systemctl restart amn-via-socks

echo "Замена прокси на '$NEW_VALUE' "

