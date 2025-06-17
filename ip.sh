#!/bin/bash

# Проверяем, что передан необходимый аргумент
if [ $# -ne 1 ]; then
    echo "Использование: $0 <новый_значение>"
    exit 1
fi

NEW_VALUE=$1

# Устанавливаем путь к файлу
FILE="amn-via-socks.sh"

# Проверяем, что файл существует
if [ ! -f "$FILE" ]; then
    echo "Файл $FILE не найден."
    exit 1
fi

# Замена части строки номер 10 от SOCKS_PROXY="socks5:// до "
sed -i '10s|SOCKS_PROXY="socks5://.*"|SOCKS_PROXY="socks5://'$NEW_VALUE'"|' "$FILE"

echo "В строке номер 10 была заменена часть на 'SOCKS_PROXY=\"$NEW_VALUE\"' в файле '$FILE'."

