#!/bin/bash
# Keepalived notification script

TYPE=$1
NAME=$2
STATE=$3

case $STATE in
    "MASTER") 
        echo "[$(date)] I am now MASTER for $NAME" > /proc/1/fd/1
        # Take over the IP
        /sbin/ip addr add ${VIRTUAL_IP}/24 dev ${INTERFACE:-eth0} label ${INTERFACE:-eth0}:1
        # Start HAProxy
        /docker-entrypoint.sh haproxy -f /usr/local/etc/haproxy/haproxy.cfg -D -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid 2>/dev/null) 2>/dev/null
        ;;
    "BACKUP") 
        echo "[$(date)] I am now BACKUP for $NAME" > /proc/1/fd/1
        # Remove the IP
        /sbin/ip addr del ${VIRTUAL_IP}/24 dev ${INTERFACE:-eth0} 2>/dev/null || true
        # Stop HAProxy
        kill -TERM $(cat /var/run/haproxy.pid 2>/dev/null) 2>/dev/null || true
        ;;
    "FAULT")
        echo "[$(date)] FAULT state for $NAME" > /proc/1/fd/1
        # Remove the IP
        /sbin/ip addr del ${VIRTUAL_IP}/24 dev ${INTERFACE:-eth0} 2>/dev/null || true
        # Stop HAProxy
        kill -TERM $(cat /var/run/haproxy.pid 2>/dev/null) 2>/dev/null || true
        ;;
    *)
        echo "[$(date)] Unknown state $STATE for $NAME" > /proc/1/fd/1
        ;;
esac

exit 0
