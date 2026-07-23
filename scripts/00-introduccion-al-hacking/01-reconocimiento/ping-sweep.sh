#!/bin/bash

function ctrl_c(){
    echo -e "[!] Saliendo del programa...\n"
    tput cnorm && exit 1
}

trap ctrl_c SIGINT

if [[ "$1" ]];then
    tput civis
    declare -a ports=$(seq 1 65335)
    
    for i in $(seq 1 254);do
        timeout 1 bash -c "ping -c 1 $1.$i" &> /dev/null && echo "[+] El host ($1.$i) esta activo" & # Basado en ping
        
        # Alternativa por si no funciona el ping
        # for port in "${ports[@]}";do
        #     timeout 1 bash -c "echo '' > /dev/tcp/$1.$i/$port" 2>/dev/null && echo "[+] El host $1.$i - Port: $port (OPEN)" &
        # done
    done
else
    echo -e "\n[!] Uso: $0 <ip-network>"
    echo -e "\t $0 192.168.10"
fi

tput cnorm