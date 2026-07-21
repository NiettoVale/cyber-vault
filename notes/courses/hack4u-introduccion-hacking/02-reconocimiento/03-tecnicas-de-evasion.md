# Técnicas de Evasión

Cuando se realizan pruebas de penetración, uno de los mayores desafíos es evadir la detección de los firewalls y sistemas de detección/prevención de intrusiones (IDS/IPS), diseñados precisamente para identificar y bloquear tráfico que se parezca a un escaneo de red. Un escaneo "de libro" con Nmap, sin ningún tipo de ajuste, genera un patrón de tráfico bastante reconocible (mismo tamaño de paquete, mismo puerto de origen, misma velocidad constante...), y cualquier firewall mínimamente configurado puede detectarlo y bloquear la IP del atacante en cuestión de segundos. Para superar este obstáculo, Nmap ofrece una variedad de técnicas de evasión, la mayoría de ellas centradas en romper ese patrón reconocible: alterar el tamaño de los paquetes, fragmentarlos, cambiar el puerto o la dirección de origen, mezclar el escaneo real entre tráfico falso, o simplemente ir más despacio de lo que un análisis automatizado esperaría.

Conviene tener presente, antes de entrar en detalle, que ninguna de estas técnicas garantiza pasar desapercibido frente a un firewall o IDS/IPS moderno bien configurado: son herramientas para dificultar la detección y reducir el ruido generado, no un método infalible de invisibilidad. Además, su uso fuera del alcance (scope) acordado con un cliente, o sin autorización explícita, puede constituir un uso indebido de estas técnicas, así que su aplicación debe quedar siempre enmarcada dentro de los términos de una auditoría autorizada.

## Fragmentación de paquetes: `-f` y `--mtu`

La opción `-f` le indica a Nmap que fragmente los paquetes que envía, dividiendo la cabecera TCP en varios fragmentos IP más pequeños en lugar de mandarla como un único paquete. La idea detrás de esta técnica es que muchos firewalls y sistemas de detección antiguos (o mal configurados) inspeccionan cada paquete de forma individual sin reensamblar antes los fragmentos, con lo que no llegan a ver la cabecera TCP completa en ningún momento y no reconocen el tráfico como un intento de escaneo. Cada uso de `-f` fragmenta el paquete en trozos de 8 bytes; si se aplica dos veces (`-ff`), los fragmentos pasan a ser de 16 bytes.

Relacionada con esta técnica está la opción `--mtu`, que permite especificar manualmente el tamaño de fragmento (en múltiplos de 8) en lugar de depender de los valores fijos que ofrece `-f`, dando un control más fino sobre cómo de "troceado" queda el tráfico generado:

```bash
❯ nmap -f 192.168.1.10
❯ nmap --mtu 16 192.168.1.10
```

## Alterar el tamaño de los paquetes: `--data-length`

Además de la fragmentación, otra forma de evitar que un escaneo se parezca a la huella por defecto de Nmap es alterar el tamaño de los paquetes enviados. Muchos sistemas de detección basados en firmas conocen el tamaño exacto que tienen los paquetes de un escaneo estándar de Nmap y los identifican precisamente por eso. La opción `--data-length` añade una cantidad determinada de bytes de datos aleatorios al final de cada paquete, haciendo que su tamaño ya no coincida con el patrón por defecto que un IDS podría estar buscando:

```bash
❯ nmap --data-length 25 192.168.1.10
```

## Puerto de origen: `--source-port` (`-g`)

Muchos firewalls, en lugar de analizar el tráfico en profundidad, aplican reglas simples basadas en el puerto de origen, confiando ciegamente en cierto tráfico solo porque parece provenir de un servicio legítimo (por ejemplo, permitiendo sin más inspección todo el tráfico que llegue desde el puerto 53, asumiendo que se trata de respuestas DNS). La opción `--source-port` (o su alias `-g`) permite forzar manualmente el puerto de origen de los paquetes de Nmap, aprovechando precisamente ese tipo de configuraciones laxas para que el escaneo se cuele como si fuera tráfico de confianza:

```bash
❯ nmap --source-port 53 192.168.1.10
```

## Señuelos: `-D`

La técnica de decoys (señuelos) consiste en mezclar el escaneo real con paquetes falsos que parecen provenir de otras direcciones IP, de forma que, desde el punto de vista del objetivo, el tráfico de escaneo parece llegar simultáneamente desde múltiples orígenes distintos en lugar de uno solo. El objetivo no es tanto pasar completamente desapercibido, sino dificultar que un analista identifique con certeza cuál de todas esas IPs es la del atacante real, entre todo el ruido de IPs señuelo:

```bash
❯ nmap -D 192.168.1.5,192.168.1.6,ME 192.168.1.10
```

En este ejemplo, `192.168.1.5` y `192.168.1.6` actúan como señuelos, y la palabra clave `ME` indica en qué posición de la lista se sitúa la IP real del atacante (si se omite, Nmap la coloca en una posición aleatoria). Es importante recalcar que esta técnica no oculta la IP real de quien escanea, solo la camufla entre tráfico adicional: un análisis más detallado (por ejemplo, revisando el campo IPID de los paquetes o correlacionando otros metadatos) puede en ciertos casos permitir distinguir cuál de las IPs era la auténtica.

## Suplantación de dirección MAC: `--spoof-mac`

La opción `--spoof-mac` permite cambiar la dirección MAC de origen que Nmap utiliza al enviar sus paquetes, ya sea especificando una dirección concreta, generando una completamente aleatoria (`--spoof-mac 0`), o incluso indicando solo el nombre o prefijo de un fabricante para que Nmap genere una MAC aleatoria pero coherente con ese fabricante (por ejemplo, simulando ser una impresora Dell en lugar del equipo real del auditor). Como se explicó en el apunte sobre direcciones IP y MAC, esta última solo tiene relevancia dentro del mismo segmento de red física, así que esta técnica únicamente resulta útil cuando el escaneo se realiza contra objetivos de la propia red local, no contra hosts remotos a través de routers:

```bash
❯ nmap --spoof-mac 0 192.168.1.10
```

## Escaneo sigiloso: `-sS`

Aunque ya se explicó en detalle al hablar del three-way handshake y de los modos de escaneo, conviene recordar que el propio SYN scan (`-sS`) es en sí mismo una técnica de evasión básica: al no completar nunca la conexión TCP (se envía el `SYN`, se recibe el `SYN-ACK` y se corta con un `RST` sin llegar al `ACK` final), el escaneo nunca llega a quedar registrado en los logs de aplicación del objetivo, que normalmente solo registran conexiones completamente establecidas.

## Controlando la velocidad del escaneo: `--scan-delay` y `--max-rate` vs `--min-rate`

La velocidad a la que se envían los paquetes es otro de los factores que más fácilmente delata un escaneo automatizado: un firewall o IDS puede activar una alerta simplemente al detectar una ráfaga de decenas de paquetes hacia distintos puertos en cuestión de milisegundos, algo que ningún uso legítimo de la red produciría. Para evadir este tipo de detección por umbral de velocidad, Nmap permite introducir una pausa mínima entre sondas con `--scan-delay`, o limitar el número máximo de paquetes por segundo que se envían con `--max-rate`, ralentizando deliberadamente el escaneo para camuflarlo entre el tráfico normal de la red:

```bash
❯ nmap --scan-delay 1s 192.168.1.10
❯ nmap --max-rate 5 192.168.1.10
```

Conviene no confundir estas opciones con `--min-rate`, que hace exactamente lo contrario: obliga a Nmap a no enviar paquetes por debajo de una velocidad mínima determinada, una opción pensada para acelerar escaneos muy grandes (por ejemplo, contra rangos enteros de IPs) y no para evadir detección. De hecho, usar `--min-rate` con un valor alto tiene el efecto contrario al de la evasión: genera más tráfico en menos tiempo, aumentando las probabilidades de disparar una alerta por volumen. Como ya se vio en el apunte anterior, las plantillas de temporización `-T0` y `-T1` cumplen un propósito similar al de `--scan-delay`, agrupando de forma más cómoda varios de estos ajustes de velocidad en un único parámetro.
