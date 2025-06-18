#!/bin/bash

while true; do
    echo "Выберите действие:"
    echo "1. Restart"
    echo "2. Stop"
    echo "3. Status"
    echo "4. Check IP"
    echo "5. Change IP"
    echo "6. Exit"

    read -p "Введите номер действия: " action

    case $action in
        1)
            echo "Перезапускаем amn-via-socks..."
            systemctl restart amn-via-socks
            ;;
        2)
            echo "Останавливаем amn-via-socks..."
            systemctl stop amn-via-socks
            ;;
        3)
            echo "Проверяем статус amn-via-socks..."
            systemctl status amn-via-socks
            ;;
        4)
            echo "Ваш внешний IP-адрес:"
            curl -s checkip.dyndns.org | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'
            ;;
        5)
            echo "Запускаем скрипт ip.sh..."
            ./ip.sh
            ;;
        6)
            echo "Выход из скрипта."
            exit 0
            ;;
        *)
            echo "Неверный выбор. Пожалуйста, попробуйте еще раз."
            ;;
    esac
    
    echo # Пустая строка для разделения выводов
done
