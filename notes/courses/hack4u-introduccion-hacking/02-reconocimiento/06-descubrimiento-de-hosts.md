# Descubrimiento de equipos en la red local (ARP e ICMP) y Tips

El descubrimiento de equipos en la red local es una tarea fundamental en la gestión de redes y en las pruebas de seguridad. Existen diferentes herramientas y técnicas para realizar esta tarea, que van desde el escaneo de puertos hasta el análisis de tráfico de red.

Cuando estamos en un equipo podemos ver que tenemos una IP asignada.

```bash
hostname -I # Nos da la IP del equipo
```

Ahora bien si quisieramos saber que equipos/hosts estan conectados en la red, podemos hacer uso de la flag `-sn` de nmap para hacer un ping sweep (descarta el escaneo de puertos y solo comprueba qué hosts responden). Otra alternativa es hacerlo con `arp-scan`, que en lugar de basarse en ICMP envía peticiones ARP directamente a nivel de enlace, algo que ningún host de la red local puede permitirse ignorar sin dejar de comunicarse; `netdiscover` funciona bajo el mismo principio (ARP) y resulta más sencillo de usar, aunque suele ser algo menos preciso que `arp-scan`.

```bash
❯ nmap -sn 192.168.10.1/24
❯ arp-scan -I eth0 --localnet --ignoredups
```

Un script con ping para hacerlo de manera manual, disponible en [`scripts/00-introduccion-al-hacking/01-reconocimiento/ping-sweep.sh`](../../../../scripts/00-introduccion-al-hacking/01-reconocimiento/ping-sweep.sh):

```bash
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
```

Este script sigue la misma lógica de paralelismo (`&`) y control de `Ctrl+C` que ya se vio en el [script de escaneo de puertos por descriptores de archivo](05-alternativas-enumeracion.md): en lugar de recorrer puertos de un único host, aquí se recorre el último octeto (`$(seq 1 254)`) de una red `/24`, asumiendo que el usuario pasa como argumento los tres primeros octetos (por ejemplo `192.168.56`, no `192.168.56.0/24`). Por cada IP candidata se lanza en segundo plano un `ping -c 1` (un único paquete ICMP) envuelto en `timeout 1` para no quedarse esperando indefinidamente la respuesta de un host que no existe; si el ping tiene éxito, se imprime que ese host está activo.

Es habitual, sobre todo dentro de una red corporativa, encontrarse con hosts que tienen el ICMP bloqueado por firewall (el ping no obtiene respuesta) pero que sí responden a nivel TCP en algún puerto. Para cubrir ese caso, el script incluye comentada una alternativa que reutiliza la técnica de descriptores de archivo (`/dev/tcp`) explicada en el apunte anterior: en vez de mandar un ping, intenta abrir una conexión TCP contra cada uno de los 65335 puertos de la IP candidata, y la considera activa si alguno responde. Esta variante es mucho más lenta (recorre miles de puertos por cada una de las 254 IPs) por lo que solo conviene descomentarla puntualmente, cuando ya se sospecha que el ICMP está siendo bloqueado en la red analizada.

```bash
❯ ./ping-sweep.sh 192.168.56

[+] El host (192.168.56.1) esta activo
[+] El host (192.168.56.10) esta activo
[+] El host (192.168.56.254) esta activo
```

Otra herramienta util es masscan la cual puede escanear millones de host por minuto, superior a los miles de host de nmap.

```bash
❯ masscan -p<puertos> -Pn 192.168.10.0/24 --rate=10000
```

Cuando estamos en una auditoria y le preguntamos al cliente si existe segmentacion en su red, ellos suelen confundir este termino con el de subnetting, por lo que podemos encontrarnos equipos en distintas redes `192.168.10.1/24, 192.168.0.0/16`, etc. Por lo que una recomendacion a la hora de hacer una auditoria es que por mas que veamos una mascara de red y realicemos el analisis de esa, habria que considerar otras redes.

Cada herramienta tiene sus propias ventajas y limitaciones. Por ejemplo, netdiscover es una herramienta simple y fácil de usar, pero puede ser menos precisa que arp-scan o masscan. Por otro lado, arp-scan y masscan son herramientas más potentes, capaces de descubrir hosts más rápido y en redes más grandes, pero también son más complejas y pueden requerir más recursos.

En definitiva, el descubrimiento de equipos en la red local es una tarea fundamental para cualquier administrador de redes o profesional de seguridad de la información. Con las técnicas y herramientas adecuadas, es posible realizar esta tarea de manera efectiva y eficiente.
