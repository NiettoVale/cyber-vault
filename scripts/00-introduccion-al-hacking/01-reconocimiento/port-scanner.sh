#!/bin/bash

function ctrl_c(){
    echo -e "\n\n[!] Saliendo del programa...\n"
    tput cnorm && exit 1
}

function checkPort(){
    # Abrimos el descriptor de archivo
    (exec 3<> /dev/tcp/"$1"/"$2") 2>/dev/null

    if [[ $? -eq 0 ]];then
        echo -e "[+] Host: $1 - Port: $2 (OPEN)"
    fi

    # Cerramos el descriptor de archivos
    exec 3<&-
    exec 3>&-
}

trap ctrl_c SIGINT

declare -a ports=( $(seq 1 65335) )

if [[ "$1" ]];then
    tput civis
    for port in "${ports[@]}";do
        checkPort "$1" "$port" & # Hacemos uso de hilos para aplicar paralelismo
    done
else
    echo -e "[!] Uso: $0 <ip-address>\n"
fi

wait
tput cnorm