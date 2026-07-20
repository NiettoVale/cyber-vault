# Direcciones IP

En ciberseguridad, prácticamente todo lo que hacemos (desde un simple escaneo hasta un ataque complejo) empieza por lo mismo: saber quién es quién dentro de una red. Antes de poder atacar, defender o incluso auditar un sistema, necesitamos un mecanismo que permita identificar de forma única a cada dispositivo conectado, para así poder dirigirnos a él, diferenciarlo de los demás y entender cómo se comunica con el resto. Ese mecanismo, de forma resumida, es la dirección IP: una especie de "matrícula" que recibe cada dispositivo cuando se conecta a una red y que nos sirve, entre otras cosas, para localizarlo y comunicarnos con él.

Con esa idea general en mente, lo mejor es verlo en la práctica. Cuando ejecutamos `ip a` o `ifconfig` en una máquina Linux, el sistema nos devuelve un listado de todas las interfaces de red disponibles junto con la configuración que tiene cada una, incluida su dirección IP. Es la primera herramienta a la que recurrimos para saber "quién somos" dentro de una red, algo fundamental antes de empezar cualquier prueba de intrusión. Una salida típica luce así:

```bash
❯ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:11:22:33:44:55 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.10/24 brd 192.168.1.255 scope global dynamic noprefixroute eth0
       valid_lft 1600sec preferred_lft 1600sec
    inet6 fe80::a1b2:c3d4:e5f6:7890/64 scope link noprefixroute
       valid_lft forever preferred_lft forever

❯ ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.10  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::a1b2:c3d4:e5f6:7890  prefixlen 64  scopeid 0x20<link>
        ether 00:11:22:33:44:55  txqueuelen 1000  (Ethernet)
        RX packets 655302  bytes 216899227 (206.8 MiB)
        TX packets 536283  bytes 599875389 (572.0 MiB)

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
```

En la salida aparecen dos interfaces: `lo`, que es la interfaz de loopback (la propia máquina hablando consigo misma, siempre con la dirección `127.0.0.1`), y `eth0`, que es la tarjeta de red física o virtual con la que el equipo se conecta al resto de dispositivos. Cada interfaz tiene asociada una dirección IP privada que la identifica dentro de esa red local. Podemos pensar en una dirección IP como una etiqueta numérica que identifica, de forma lógica y jerárquica, a una interfaz de un dispositivo que utiliza el Protocolo de Internet (IP), de la misma manera que un número de casa identifica una vivienda dentro de una calle. Si solo necesitamos la IP sin todo el resto de información, el comando `hostname -I` nos la devuelve directamente.

Una dirección IPv4 está formada por 32 bits, organizados en cuatro grupos de 8 bits cada uno (llamados octetos), separados por puntos. Cada octeto puede representarse en decimal (el formato que usamos habitualmente, de 0 a 255) o en binario. Por ejemplo, la IP `192.168.1.10` se puede convertir octeto por octeto a binario de la siguiente manera:

```bash
❯ echo "$(echo "obase=2; 192" | bc)."$(echo "obase=2; 168" | bc)"."$(echo "obase=2; 1" | bc)"."$(echo "obase=2; 10" | bc)""
11000000.10101000.00000001.00001010 # Representación en binario de la IP 192.168.1.10
```

Como cada octeto tiene 8 bits y hay 4 octetos, el total de bits de una IPv4 es 32. Esto significa que el número máximo de direcciones IP distintas que se pueden formar es 2 elevado a 32:

```bash
❯ echo "2^32" | bc
4294967296 # 4.294.967.296 direcciones IPv4 posibles en total
```

Aunque a simple vista parezca una cifra enorme, el número de dispositivos conectados a Internet (móviles, ordenadores, routers, cámaras IP, sensores IoT, etc.) ha crecido tanto que ese espacio de direcciones se ha quedado corto: hay más dispositivos que necesitan una IP que direcciones IPv4 disponibles. Para solucionar este problema de raíz surgió IPv6, un nuevo estándar que en lugar de usar 32 bits utiliza 128 bits, ampliando drásticamente el espacio disponible:

```bash
❯ echo "2^128" | bc
340282366920938463463374607431768211456
```

Esa cifra es tan grande que, en la práctica, permite asignar una dirección única a cada dispositivo que pueda llegar a fabricarse, eliminando el problema de escasez que sufre IPv4. Aun así, IPv4 sigue siendo el protocolo más usado hoy en día gracias a mecanismos como el NAT (que permite que muchos dispositivos de una red privada compartan una única IP pública).

Para un pentester, la dirección IP es el punto de partida de cualquier auditoría: al identificar la IP de una máquina objetivo, se pueden lanzar escaneos de puertos y servicios (por ejemplo, con herramientas como `nmap`) para descubrir qué servicios están expuestos y son potencialmente vulnerables. Por ejemplo, un escaneo básico como `nmap 192.168.1.10` nos permitiría ver qué puertos TCP están abiertos en esa máquina y empezar a mapear la superficie de ataque.

# Direcciones MAC

Mientras que la IP identifica a un dispositivo dentro de una red (y puede cambiar según a qué red nos conectemos), la dirección MAC (Media Access Control) identifica de forma física a la tarjeta de red en sí, sin importar a qué red esté conectada. Es un número hexadecimal de 12 dígitos, equivalente a 6 bytes (48 bits), que se representa habitualmente separando cada byte con dos puntos, por ejemplo `00:11:22:33:44:55`.

La MAC se divide en dos mitades con significados distintos. Los primeros 6 dígitos hexadecimales (3 bytes, 24 bits) forman el llamado OUI (Identificador Único Organizacional) e identifican al fabricante de la tarjeta de red; estos prefijos son asignados por el Comité de la Autoridad de Registro de IEEE a cada proveedor registrado. Los últimos 6 dígitos hexadecimales (los otros 3 bytes) identifican al controlador de interfaz de red en sí, un número que asigna el propio fabricante para diferenciar cada tarjeta que produce. Dicho de otro modo: la primera mitad nos dice "quién lo fabricó" y la segunda mitad nos dice "cuál de todas las tarjetas de ese fabricante es esta en concreto".

Esto tiene una aplicación práctica muy directa: a partir de los primeros 3 bytes de una MAC podemos averiguar qué fabricante produjo la tarjeta de red, consultando bases de datos públicas de OUI (por ejemplo, la que mantiene el propio IEEE). Por ejemplo, si en un escaneo de red descubrimos un dispositivo con la MAC `00:1A:2B:11:22:33`, buscando el prefijo `00:1A:2B` en un buscador de OUI podríamos identificar si se trata de una tarjeta de un fabricante concreto, lo cual es útil en un pentest para hacernos una idea de qué tipo de dispositivo tenemos delante (un router, una impresora, un móvil, una máquina virtual, etc.) incluso antes de haber interactuado con sus servicios.
