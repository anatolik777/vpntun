#!/bin/bash
set -euo pipefail

# Конфигурация
TUN_DEV="tun0"
TUN_ADDR="10.0.0.2/24"
FWMARK="100"
ROUTE_TABLE="100"
CONTAINER_IP="172.29.172.2"
SOCKS_PROXY="socks5://84f0:84f0@188.245.47.167:25158"
TUN2SOCKS_BIN="/usr/local/bin/tun2socks"

cleanup() {
    echo "[INFO] Очищаем iptables, маршруты и интерфейс..."
    iptables -t mangle -D PREROUTING -s "$CONTAINER_IP" -p tcp -j MARK --set-mark "$FWMARK" 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o "$TUN_DEV" -j MASQUERADE 2>/dev/null || true
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

echo "[INFO] Настройка ip rule и iptables..."
ip rule add fwmark "$FWMARK" table "$ROUTE_TABLE" priority "$FWMARK"
ip route replace default dev "$TUN_DEV" table "$ROUTE_TABLE"

iptables -t mangle -A PREROUTING -s "$CONTAINER_IP" -p tcp -j MARK --set-mark "$FWMARK"
iptables -t nat -A POSTROUTING -o "$TUN_DEV" -j MASQUERADE

echo "[INFO] Запуск tun2socks..."
exec "$TUN2SOCKS_BIN" \
  --device "$TUN_DEV" \
  --proxy "$SOCKS_PROXY"
