<%\*
let nombre = await tp.system.prompt("Nombre del Objetivo:");
let target_ip = await tp.system.prompt("IP del objetivo:", "10.10.10.");
let os_type = await tp.system.suggester(["Linux", "Windows", "Otro"], ["Linux", "Windows", "Otro"], false, "Sistema Operativo:");
let dif_level = await tp.system.suggester(["Fácil", "Media", "Difícil", "Insana"], ["Fácil", "Media", "Difícil", "Insana"], false, "Dificultad:");
let plataforma = await tp.system.suggester(["HackTheBox", "TryHackMe", "VulnHub", "Otro"], ["HackTheBox", "TryHackMe", "VulnHub", "Otro"], false, "Plataforma:");
let status = await tp.system.suggester(["En Progreso", "Completada", "Abandonada"], ["En Progreso", "Completada", "Abandonada"], false, "Estado:");
let tag_os = os_type.toLowerCase();
let tag_dif = dif_level.toLowerCase();
let tag_plat = plataforma.toLowerCase().replace(" ", "-");
await tp.file.rename(nombre);
-%>

---

title: "<% tp.file.title %>"
date: <% tp.date.now("YYYY-MM-DD") %>
author: NiettoVale
target_ip: <% target_ip %>
os: <% os_type %>
difficulty: <% dif_level %>
platform: <% plataforma %>
status: <% status %>
tags:

- reporte
- pentest
- <% tag_os %>
- <% tag_dif %>
- <% tag_plat %>

---

# <% tp.file.title %>

| Campo                 | Detalle                         |
| :-------------------- | :------------------------------ |
| **Objetivo**          | <% tp.file.title %>             |
| **IP**                | `<% target_ip %>`               |
| **Sistema Operativo** | <% os_type %>                   |
| **Dificultad**        | <% dif_level %>                 |
| **Plataforma**        | <% plataforma %>                |
| **Fecha**             | <% tp.date.now("DD/MM/YYYY") %> |
| **Auditor**           | NiettoVale                      |
| **Estado**            | <% status %>                    |

---

## 1. Resumen Ejecutivo

> Síntesis de alto nivel del compromiso. Completar al finalizar la máquina.

Durante la evaluación de seguridad sobre **<% tp.file.title %>** (`<% target_ip %>`), se logró comprometer totalmente el sistema obteniendo privilegios de `[root / SYSTEM]`. El vector de entrada principal fue `[descripción breve]`, explotado mediante `[técnica/herramienta]`. La escalada de privilegios se realizó a través de `[mecanismo]`.

**Clasificación de riesgo general:** `CRÍTICO / ALTO / MEDIO / BAJO`

---

## 2. Cadena de Ataque (Attack Chain)

> Narrativa lineal del compromiso completo. Una línea por paso.

1. **Reconocimiento:** Enumeración de puertos reveló `[servicios]` expuestos.
2. **Enumeración:** Se identificó `[tecnología/versión/recurso]` con `[herramienta]`.
3. **Explotación:** Se abusó de `[CVE / vulnerabilidad]` para obtener ejecución remota / acceso no autenticado.
4. **Acceso Inicial:** Shell interactiva como usuario `[nombre]`.
5. **Enumeración Interna:** Se identificó `[vector de privesc]` mediante `[herramienta/técnica]`.
6. **Escalada de Privilegios:** Pivote a `[root / Administrator]` vía `[mecanismo]`.

---

## 3. Análisis Técnico

### 3.1 Reconocimiento

#### Escaneo de Puertos

```bash
# Descubrimiento rápido de puertos abiertos
nmap -p- --open -sS --min-rate 5000 -n -Pn <% target_ip %> -oG allPorts

# Enumeración de servicios y versiones sobre puertos hallados
nmap -p [PUERTOS] -sCV <% target_ip %> -oN targeted
```

**Puertos y servicios identificados:**

|   Puerto   | Estado | Servicio     | Versión     |
| :--------: | :----: | :----------- | :---------- |
| `[puerto]` |  open  | `[servicio]` | `[versión]` |
| `[puerto]` |  open  | `[servicio]` | `[versión]` |

#### Enumeración de Servicio(s)

> Documentar herramientas y hallazgos por cada servicio relevante (HTTP, SMB, FTP, etc.)

```bash
# Ejemplo: enumeración web
gobuster dir -u http://<% target_ip %>/ -w /usr/share/wordlists/dirb/common.txt -x php,html,txt
```

**Hallazgos:**

- `[ruta / recurso / tecnología identificada]`
- `[usuario / credencial / archivo sensible encontrado]`

---

### 3.2 Acceso Inicial (Foothold)

> Describir el vector de ataque, el porqué funciona y los pasos exactos para reproducirlo.

**Vulnerabilidad:** `[Nombre / CVE]`
**Servicio afectado:** `[servicio:puerto]`
**Herramienta/técnica:** `[nombre]`

**Procedimiento:**

```bash
# Paso 1: [descripción]
[comando]

# Paso 2: [descripción]
[comando]
```

**Resultado:** Shell como `[usuario]` en `<% target_ip %>`.

```
[usuario]@<% tp.file.title %>:~$ id
uid=XXX([usuario]) gid=XXX([grupo]) groups=...
```

**Flag de usuario:**

```
[hash de user.txt]
```

---

### 3.3 Escalada de Privilegios

> Documentar la enumeración post-explotación y el camino hacia root/SYSTEM.

#### Enumeración Interna

```bash
# Herramientas y comandos de enumeración utilizados
[comando de enumeración, ej: sudo -l, find / -perm -4000, linpeas.sh, etc.]
```

**Hallazgos relevantes:**

- `[binario SUID / tarea cron / credencial / misconfiguration encontrada]`

#### Explotación del Vector de Privesc

**Vector:** `[nombre del vector, ej: sudo misconfiguration, SUID binary, token impersonation]`

```bash
# Pasos para la escalada
[comandos exactos]
```

**Resultado:** Shell como `root` / `SYSTEM`.

```
root@<% tp.file.title %>:~# id
uid=0(root) gid=0(root) groups=0(root)
```

**Flag de root:**

```
[hash de root.txt]
```

---

## 4. Vulnerabilidades Identificadas

### 4.1 `[Nombre de la Vulnerabilidad]`

| Campo                | Detalle                                       |
| :------------------- | :-------------------------------------------- |
| **CVE**              | `CVE-XXXX-XXXXX` / N/A                        |
| **CWE**              | `CWE-XXX` – [nombre del weakness]             |
| **CVSS v3.1**        | `X.X (CRÍTICO / ALTO / MEDIO / BAJO)`         |
| **Sistema Afectado** | `<% target_ip %>` – [servicio:puerto]         |
| **Tipo**             | `[RCE / SQLi / LFI / Misconfiguration / ...]` |

**Descripción técnica:**
`[Explicar la falla a nivel técnico: qué componente es vulnerable, qué input/condición lo dispara y por qué el sistema lo procesa incorrectamente.]`

**Impacto:**
Un atacante no autenticado puede `[acción]`, comprometiendo la `[confidencialidad / integridad / disponibilidad]` del sistema.

**Remediación:**

- **Inmediata:** `[acción de contención, ej: deshabilitar el servicio, aplicar regla de firewall]`
- **Corto plazo:** `[parche / actualización / cambio de configuración específico]`
- **Largo plazo:** `[control estructural: hardening, revisión de código, WAF, etc.]`

---

> Repetir sección 4.x por cada vulnerabilidad adicional encontrada.

---

## 5. Evidencias (Proof of Concept)

> Hashes criptográficos y capturas que certifican el acceso a cada nivel del sistema.

### User Flag

```
[hash completo de user.txt]
```

_Comando ejecutado:_ `cat /home/[usuario]/user.txt`

### Root Flag

```
[hash completo de root.txt]
```

_Comando ejecutado:_ `cat /root/root.txt`

---

## 6. Referencias

- `[CVE / herramienta / writeup de referencia con URL]`
- `[Documentación oficial relevante]`
