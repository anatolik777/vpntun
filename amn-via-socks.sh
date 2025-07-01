#!/bin/bash
set -euo pipefail

# Конфигурация
TUN_DEV="tun0"
TUN_ADDR="10.0.0.2/24"
FWMARK="100"
ROUTE_TABLE="100"
CONTAINER_IP="172.29.172.2"
SOCKS_PROXY="socks5://PP1WFVe0365fscv:B8QM5Gfp4bbir7V@107.180.162.1:57941"
TUN2SOCKS_BIN="/usr/local/bin/tun2socks"
EXCLUDE_UDP_PORT="44985"  # Порт, который НЕ надо проксировать (например, для локального сервиса)
EXCLUDE_RULE_PRIORITY=$((FWMARK - 2))  # Приоритет для исключающего правила

cleanup() {
    echo "[INFO] Очищаем iptables, маршруты и интерфейс..."

    iptables -t mangle -D PREROUTING -s "$CONTAINER_IP" -p tcp -j MARK --set-mark "$FWMARK" 2>/dev/null || true
    iptables -t mangle -D PREROUTING -s "$CONTAINER_IP" -p udp ! --dport "$EXCLUDE_UDP_PORT" -j MARK --set-mark "$FWMARK" 2>/dev/null || true
    iptables -t mangle -D POSTROUTING -p udp --sport "$EXCLUDE_UDP_PORT" -j MARK --set-mark 0 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o "$TUN_DEV" -j MASQUERADE 2>/dev/null || true

    ip rule del ipproto udp sport "$EXCLUDE_UDP_PORT" table main priority "$EXCLUDE_RULE_PRIORITY" 2>/dev/null || true
    ip rule del fwmark "$FWMARK" table "$ROUTE_TABLE" priority "$FWMARK" 2>/dev/null || true
    ip route flush table "$ROUTE_TABLE" || true

    ip link set "$TUN_DEV" down 2>/dev/null || true
    ip tuntap del dev "$TUN_DEV" mode tun 2>/dev/null || true
}

# Если передан аргумент stop — только cleanup
if [[ "${1:-}" == "stop" ]]; then
    cleanup
    exit 0
fi

# При старте настраиваем всё
trap cleanup EXIT

echo "[INFO] Создание интерфейса $TUN_DEV..."
if ip link show "$TUN_DEV" &>/dev/null; then
    echo "[WARN] Интерфейс $TUN_DEV уже существует. Удаляю..."
    ip link set "$TUN_DEV" down || true
    ip tuntap del dev "$TUN_DEV" mode tun || true
fi

ip tuntap add dev "$TUN_DEV" mode tun
ip addr add "$TUN_ADDR" dev "$TUN_DEV"
ip link set "$TUN_DEV" up

echo "[INFO] Настройка ip rule и маршрутизации..."
ip rule add ipproto udp sport "$EXCLUDE_UDP_PORT" table main priority "$EXCLUDE_RULE_PRIORITY"
ip rule add fwmark "$FWMARK" table "$ROUTE_TABLE" priority "$FWMARK"
ip route replace default dev "$TUN_DEV" table "$ROUTE_TABLE"

echo "[INFO] Настройка iptables (маркировка трафика)..."

# TCP трафик — весь
iptables -t mangle -A PREROUTING -s "$CONTAINER_IP" -p tcp -j MARK --set-mark "$FWMARK"

# UDP трафик, кроме порта EXCLUDE_UDP_PORT
iptables -t mangle -A PREROUTING -s "$CONTAINER_IP" -p udp ! --dport "$EXCLUDE_UDP_PORT" -j MARK --set-mark "$FWMARK"

# Исключаем ОТВЕТНЫЙ трафик с портом 44985 от перенаправления в tun0
iptables -t mangle -A POSTROUTING -p udp --sport "$EXCLUDE_UDP_PORT" -j MARK --set-mark 0

# NAT на TUN-интерфейсе
iptables -t nat -A POSTROUTING -o "$TUN_DEV" -j MASQUERADE

echo "[INFO] Запуск tun2socks..."
exec "$TUN2SOCKS_BIN" \
  --device "$TUN_DEV" \
  --proxy "$SOCKS_PROXY"
