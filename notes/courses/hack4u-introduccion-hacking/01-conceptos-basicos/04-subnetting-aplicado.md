# Interpretación de Rangos para Auditorías

Todo lo visto hasta ahora sobre subnetting deja de ser teoría el día en que un cliente nos entrega el alcance (scope) de una auditoría. En ese momento, saber leer con precisión qué rango de direcciones estamos autorizados a tocar deja de ser un ejercicio académico y pasa a ser, literalmente, el límite legal de lo que podemos hacer: salirnos de ese rango, aunque sea por error de interpretación, puede significar estar atacando sistemas para los que no tenemos autorización.

Un cliente puede entregarnos el alcance de formas muy distintas, y conviene reconocerlas todas:

- **Notación CIDR**, la más común y la más precisa: `192.168.1.0/24`. Aquí, aplicando lo aprendido en el apunte anterior, sabemos exactamente qué Network ID, qué Broadcast y qué rango de hosts utilizables incluye.
- **Rango explícito de IPs**: `192.168.1.10 - 192.168.1.50`, indicando directamente la primera y la última IP incluidas, sin pasar por el concepto de máscara.
- **Notación abreviada de rango**: `192.168.1.10-50`, donde se sobreentiende que solo cambia el último octeto entre el valor inicial y el final.
- **Lista de IPs sueltas o de múltiples subredes**, normalmente entregada en un archivo de texto, cuando el alcance no es un bloque contiguo sino una colección de sistemas puntuales repartidos en distintas redes.

El punto importante es que un rango de IPs "a mano" (como `192.168.1.10 - 192.168.1.50`) no siempre coincide con un único bloque CIDR limpio. Por ejemplo, ese rango en concreto no corresponde a ningún `/n` exacto, porque un bloque CIDR siempre empieza en un múltiplo de su propio tamaño de bloque (como vimos con el "número mágico") y este rango ni empieza ni termina en uno de esos límites. Si necesitamos expresar ese rango como uno o varios bloques CIDR (por ejemplo, para cargarlo en una herramienta que solo acepta notación CIDR), hay que descomponerlo en el conjunto más pequeño de bloques que lo cubran exactamente, sin incluir direcciones de más ni de menos; esta técnica se conoce como agregación de CIDR y la retomamos con más detalle en la siguiente sección al hablar de sumarización de rutas.

En la práctica, la mayoría de las herramientas de escaneo aceptan directamente estos formatos sin que tengamos que convertirlos a mano:

```bash
❯ nmap 192.168.1.0/24        # notación CIDR
❯ nmap 192.168.1.10-50       # rango abreviado
❯ nmap -iL alcance.txt       # lista de IPs/rangos desde un archivo
```

Aun así, es una buena práctica calcular manualmente el Network ID y el Broadcast del alcance recibido y compararlos con lo que entiende la herramienta, precisamente para detectar a tiempo cualquier malentendido: es muy fácil, por ejemplo, leer mal un `/23` como si fuera un `/24` y terminar incluyendo (o excluyendo) sin querer 256 direcciones de otra subred que quizás no está autorizada.

# Casos Particulares y Redes Extrañas

No todas las máscaras y rangos que nos vamos a encontrar siguen el patrón "normal" de una red con Network ID, hosts utilizables y Broadcast. Existen varios casos especiales que conviene reconocer de memoria porque rompen (o casi rompen) las reglas generales.

**Prefijo /31 — enlaces punto a punto.** Según la fórmula general, una subred `/31` solo tiene `2^1 = 2` direcciones, y como normalmente se reservan una para Network ID y otra para Broadcast, no quedaría ninguna dirección utilizable. Sin embargo, el RFC 3021 define una excepción específica para este caso: en enlaces punto a punto (por ejemplo, el cable que conecta dos routers entre sí, sin ningún otro dispositivo de por medio), no hace falta reservar ni Network ID ni Broadcast, así que las dos direcciones se usan como hosts válidos, una para cada extremo del enlace. Es una forma de ahorrar direcciones IP en infraestructuras con muchísimos enlaces punto a punto, como las redes troncales de un ISP.

**Prefijo /32 — una única dirección.** Un `/32` no deja ningún bit para hosts (`2^0 = 1`), por lo que representa una sola dirección IP exacta, sin red ni broadcast que calcular. Se usa típicamente en rutas estáticas para dirigir tráfico hacia un host específico, o para identificar la interfaz de loopback de un router.

**Prefijo /0 — toda la Internet IPv4.** En el extremo opuesto, `0.0.0.0/0` representa el bloque más grande posible: las 2^32 direcciones IPv4 completas. No se usa para asignar direcciones a hosts, sino como notación para "cualquier destino", y es la forma en la que se expresa la ruta por defecto (default route) en las tablas de enrutamiento: "si no sabes a dónde mandar este paquete, mándalo por aquí".

**Rangos reservados que no son asignables a hosts normales.** Existen varios bloques de direcciones que la IANA ha reservado para usos especiales y que jamás deberíamos ver como una IP pública "normal" en Internet:

| Rango | Prefijo | Uso |
|-------|---------|-----|
| 10.0.0.0 – 10.255.255.255 | /8 | Privado (RFC 1918) |
| 172.16.0.0 – 172.31.255.255 | /12 | Privado (RFC 1918) |
| 192.168.0.0 – 192.168.255.255 | /16 | Privado (RFC 1918) |
| 127.0.0.0 – 127.255.255.255 | /8 | Loopback (la propia máquina) |
| 169.254.0.0 – 169.254.255.255 | /16 | Link-local / APIPA (autoasignada cuando falla el DHCP) |
| 100.64.0.0 – 100.127.255.255 | /10 | CGNAT (usado por ISPs para compartir IP pública entre varios clientes) |
| 224.0.0.0 – 239.255.255.255 | /4 | Multicast |
| 192.0.2.0, 198.51.100.0, 203.0.113.0 | /24 cada uno | Documentación (TEST-NET, se usan en manuales y ejemplos) |
| 255.255.255.255 | /32 | Broadcast limitado |

Reconocer estos rangos es útil en una auditoría: si durante un escaneo aparece una IP `169.254.x.x`, por ejemplo, sabemos de inmediato que ese host no logró obtener una IP por DHCP y se autoasignó una (un síntoma de un problema de red, no una IP "real" de producción); o si vemos tráfico dirigido a `127.0.0.1` en una captura, sabemos que es la propia máquina hablándose a sí misma.

**Sumarización de rutas (supernetting).** Es, en cierto modo, la operación inversa al subnetting: en lugar de dividir una red grande en subredes pequeñas, se combinan varias subredes contiguas del mismo tamaño en un único bloque más grande, para simplificar las tablas de enrutamiento de un router (una sola entrada de ruta en vez de varias). Para que esto sea posible, los bloques deben ser contiguos, del mismo tamaño y estar alineados a un límite válido de bloque mayor. Por ejemplo, `192.168.0.0/24` y `192.168.1.0/24` pueden resumirse en un único bloque `192.168.0.0/23`, porque juntos forman exactamente un bloque de 512 direcciones que empieza en un múltiplo válido de 512. En cambio, `192.168.1.0/24` y `192.168.2.0/24` no se pueden resumir en un solo `/23`, porque no están alineados al mismo límite de bloque (el resultado incluiría direcciones que no pertenecen a ninguna de las dos redes originales).

**Wildcard masks.** Un caso que suele generar confusión, sobre todo en equipos Cisco, son las wildcard masks, usadas en listas de control de acceso (ACLs) y en protocolos de enrutamiento como OSPF. Es, esencialmente, la máscara de subred con los bits invertidos (0 donde la máscara tiene 1, y 1 donde la máscara tiene 0). Así, la máscara `255.255.255.0` (/24) tiene como wildcard mask equivalente `0.0.0.255`. Mientras que una máscara de subred normal siempre debe tener sus bits en "1" contiguos desde la izquierda, una wildcard mask técnicamente permite patrones no contiguos para seleccionar bits sueltos en reglas muy específicas, aunque en la inmensa mayoría de los casos prácticos se usa simplemente como el inverso exacto de una máscara de subred normal.

# Tips de Cálculo Rápido

Para cerrar, conviene fijar el método completo de cálculo manual con un ejemplo resuelto muy despacio, paso a paso, y después reforzarlo con dos ejemplos adicionales resueltos con el mismo procedimiento, para practicar con prefijos y clases distintas.

## Ejemplo 1: `172.14.15.16/17`

**Paso 1 — Convertir la IP a binario.** Traducimos cada uno de los cuatro octetos decimales a su equivalente binario de 8 bits:

```
172 → 10101100
14  → 00001110
15  → 00001111
16  → 00010000
```

IP completa en binario: `10101100.00001110.00001111.00010000`

**Paso 2 — Construir la máscara a partir del prefijo.** El prefijo es `/17`, así que colocamos 17 bits en "1" (empezando desde la izquierda) y rellenamos el resto, hasta completar los 32 bits, con "0":

```
11111111.11111111.10000000.00000000
```

Convirtiendo cada octeto a decimal: `255.255.128.0`. Como el primer octeto (172) cae en el rango 128–191, es una dirección de Clase B, aunque recordemos que al usar CIDR la clase original ya no determina el tamaño real de la red: aquí estamos usando un `/17`, más pequeño que el `/16` por defecto de Clase B.

**Paso 3 — Calcular el Network ID con un AND lógico.** Comparamos bit a bit la IP y la máscara: el resultado es "1" solo donde ambos bits son "1", y "0" en cualquier otro caso. Esto conserva intacta la parte de red y apaga por completo la parte de host:

```
      IP:  10101100.00001110.00001111.00010000
  Máscara: 11111111.11111111.10000000.00000000
  ---------------------------------------------
      AND: 10101100.00001110.00000000.00000000  →  172.14.0.0
```

**Paso 4 — Calcular el Broadcast poniendo a "1" todos los bits de host.** Primero identificamos cuántos bits de host tenemos: `32 - 17 = 15` bits. Manteniendo intactos los 17 bits de red que ya calculamos, ponemos los 15 bits de host restantes en "1":

```
Red (17 bits, sin tocar): 10101100.00001110.0
Host (15 bits, a "1"):                       1111111.11111111
Resultado completo:       10101100.00001110.01111111.11111111  →  172.14.127.255
```

**Paso 5 — Calcular la cantidad de hosts utilizables.** Con 15 bits de host, el total de direcciones en la subred es `2^15 = 32.768`, y restando el Network ID y el Broadcast quedan `32.768 - 2 = 32.766` hosts utilizables.

**Resultado final:**

| Campo | Valor |
|-------|-------|
| IP del cliente | 172.14.15.16 |
| Máscara de red | 255.255.128.0 |
| Network ID | 172.14.0.0 |
| Broadcast Address | 172.14.127.255 |
| Rango de hosts utilizables | 172.14.0.1 – 172.14.127.254 |
| Cantidad de hosts utilizables | 32.766 |

## Ejemplo 2: `10.20.130.5/20`

Repetimos exactamente el mismo procedimiento con una IP de Clase A y un prefijo distinto.

**Paso 1 — Binario:**

```
10  → 00001010
20  → 00010100
130 → 10000010
5   → 00000101
```

IP: `00001010.00010100.10000010.00000101`

**Paso 2 — Máscara para /20:** 20 bits en "1", 12 bits en "0":

```
11111111.11111111.11110000.00000000  →  255.255.240.0
```

**Paso 3 — Network ID (AND lógico):**

```
      IP:  00001010.00010100.10000010.00000101
  Máscara: 11111111.11111111.11110000.00000000
  ---------------------------------------------
      AND: 00001010.00010100.10000000.00000000  →  10.20.128.0
```

Fíjate en el tercer octeto: `130` en binario es `10000010`, y al aplicar el AND con `11110000` solo sobreviven los primeros 4 bits (`1000`), lo que da `10000000` = `128`. Esto ilustra un caso en el que el "corte" entre red y host cae a mitad de un octeto, y por eso conviene siempre resolverlo en binario en vez de intentar adivinarlo directamente en decimal.

**Paso 4 — Broadcast:** con `32 - 20 = 12` bits de host, ponemos esos 12 bits en "1" manteniendo la parte de red:

```
10001010... → conservando 20 bits de red: 00001010.00010100.1000
Bits de host (12, a "1"):                              1111.11111111
Resultado: 00001010.00010100.10001111.11111111  →  10.20.143.255
```

**Paso 5 — Hosts utilizables:** `2^12 - 2 = 4.094` hosts utilizables.

**Resultado final:**

| Campo | Valor |
|-------|-------|
| IP del cliente | 10.20.130.5 |
| Máscara de red | 255.255.240.0 |
| Network ID | 10.20.128.0 |
| Broadcast Address | 10.20.143.255 |
| Rango de hosts utilizables | 10.20.128.1 – 10.20.143.254 |
| Cantidad de hosts utilizables | 4.094 |

## Ejemplo 3: `192.168.50.77/27`

Un tercer ejemplo, esta vez con una IP de Clase C y un prefijo que cae completamente dentro del último octeto, útil para comparar con el método del "número mágico" visto en el apunte anterior.

**Paso 1 — Binario:**

```
192 → 11000000
168 → 10101000
50  → 00110010
77  → 01001101
```

IP: `11000000.10101000.00110010.01001101`

**Paso 2 — Máscara para /27:** 27 bits en "1", 5 bits en "0". Como los primeros 24 bits ya completan tres octetos enteros, los 3 bits adicionales del prefijo se toman del último octeto:

```
11111111.11111111.11111111.11100000  →  255.255.255.224
```

**Paso 3 — Network ID (AND lógico):** en los primeros tres octetos no cambia nada (la máscara es `255` en los tres), así que solo hace falta operar el último octeto: `01001101` (77) AND `11100000` (224):

```
  01001101
  11100000
  --------
  01000000  → 64
```

Network ID: `192.168.50.64`

**Paso 4 — Broadcast:** con `32 - 27 = 5` bits de host, ponemos esos 5 bits del último octeto en "1", manteniendo los 3 bits de red que ya calculamos (`010`):

```
010 (red) + 11111 (host) = 01011111  → 95
```

Broadcast: `192.168.50.95`

**Paso 5 — Hosts utilizables:** `2^5 - 2 = 30` hosts utilizables.

**Verificación cruzada con el método del número mágico:** el octeto interesante vale `224`, así que el bloque es `256 - 224 = 32`. Los múltiplos de 32 son `0, 32, 64, 96...`; nuestra IP termina en `.77`, que cae entre `64` y `96`, confirmando exactamente el mismo Network ID (`.64`) y Broadcast (`.95` = `96 - 1`) que obtuvimos por binario.

**Resultado final:**

| Campo | Valor |
|-------|-------|
| IP del cliente | 192.168.50.77 |
| Máscara de red | 255.255.255.224 |
| Network ID | 192.168.50.64 |
| Broadcast Address | 192.168.50.95 |
| Rango de hosts utilizables | 192.168.50.65 – 192.168.50.94 |
| Cantidad de hosts utilizables | 30 |
