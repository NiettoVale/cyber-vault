# Alternativa para la enumeracion de puertos usando descriptores de archivos

En el mundo de la ciberseguridad siempre es bueno tener diversas formas de realizar una misma cosa, esto por si en algun momento no nos funciona una herramienta, tengamos una alternativa. En este caso vamos a crear un script en bash el cual nos va a permitir escanear puertos usando descriptores de archivos.

Esta alternativa cobra sentido sobre todo en escenarios donde Nmap no es la mejor opción: por un lado, muchos IDS/IPS y firewalls tienen firmas muy específicas para reconocer el tráfico que genera Nmap (incluso con las técnicas de evasión ya vistas), así que un script propio y minimalista como este, al no comportarse como Nmap, puede pasar más desapercibido. Por otro lado, hay entornos (máquinas restringidas, contenedores mínimos, algunos CTFs) donde directamente no se dispone de Nmap instalado ni de permisos para instalarlo, y en cambio casi siempre hay disponible un intérprete de Bash, lo que convierte a este script en una alternativa portable que no depende de herramientas externas.

## Descriptores de archivo y `/dev/tcp`

Bash incluye una característica poco conocida: en lugar de operar solo sobre ficheros reales, es capaz de tratar direcciones `/dev/tcp/<host>/<puerto>` como si fueran un fichero especial, delegando en el propio sistema el intento de abrir una conexión TCP contra ese host y puerto. Al redirigir la entrada/salida hacia esa ruta con `exec`, Bash intenta completar el three-way handshake por debajo; si lo consigue, la apertura del descriptor se resuelve con éxito y **si el puerto está cerrado o filtrado, falla**. En ambos casos, el resultado queda reflejado en la variable `$?` (el código de salida del último comando), que es precisamente lo que el script usa para decidir si el puerto está abierto o no.

El script completo, disponible en [`scripts/00-introduccion-al-hacking/01-reconocimiento/port-scanner.sh`](../../../../scripts/00-introduccion-al-hacking/01-reconocimiento/port-scanner.sh), es el siguiente:

```bash
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
```

## Funcionamiento paso a paso

- **`checkPort()`**: es la función central. `exec 3<> /dev/tcp/"$1"/"$2"` abre el descriptor de archivo número `3` en modo lectura/escritura (`<>`) contra el host y puerto recibidos como parámetros; se ejecuta dentro de un subshell `(...)` para que, si falla, no cierre la sesión de Bash actual, y se redirige `2>/dev/null` para descartar el mensaje de error que se imprimiría si la conexión no puede establecerse. Justo después se comprueba `$?`: si vale `0`, la conexión se completó y el puerto está abierto. Al final, la función cierra explícitamente el descriptor de lectura (`3<&-`) y el de escritura (`3>&-`) para no dejar conexiones ni descriptores abiertos innecesariamente.
- **`trap ctrl_c SIGINT`**: captura la señal `SIGINT` (`Ctrl+C`) para que, si el usuario interrumpe el escaneo a mitad de ejecución, el script salga de forma controlada en lugar de dejar el cursor invisible en la terminal.
- **`declare -a ports=( $(seq 1 65335) )`**: genera un array con el rango completo de puertos a comprobar (del 1 al 65335) usando `seq`.
- **Paralelismo con `&`**: el script no comprueba los puertos uno a uno de forma secuencial, sino que lanza cada llamada a `checkPort` como un proceso en segundo plano (`&`), lanzando así miles de comprobaciones casi simultáneas. Esto es lo que hace viable escanear los ~65000 puertos en un tiempo razonable, ya que cada comprobación individual puede tardar en fallar por timeout si el puerto está filtrado. El `wait` final del script espera a que todos esos procesos en segundo plano terminen antes de finalizar.
- **`tput civis` / `tput cnorm`**: ocultan y vuelven a mostrar el cursor de la terminal, respectivamente, un detalle puramente estético para que la salida de los cientos de procesos en paralelo no quede interrumpida por el parpadeo del cursor.

## Uso

```bash
❯ ./port-scanner.sh 192.168.1.10

[+] Host: 192.168.1.10 - Port: 22 (OPEN)
[+] Host: 192.168.1.10 - Port: 80 (OPEN)
[+] Host: 192.168.1.10 - Port: 443 (OPEN)
```

Al lanzar tantos procesos en paralelo sin ningún tipo de límite, conviene tener en cuenta que este script es bastante más ruidoso y menos eficiente en gestión de recursos que Nmap (que sí controla la concurrencia y aplica timeouts optimizados), por lo que en redes lentas o con muchos hosts filtrados puede generar una carga notable tanto en la máquina atacante como en la red. Aun así, como alternativa ligera, sin dependencias externas y capaz de operar solo con las utilidades propias de Bash, resulta muy útil precisamente en esos casos en los que Nmap no es una opción viable.
