# Módulo 3 — Modelo OSI

## Contenido

- [¿Qué es el modelo OSI?](#qué-es-el-modelo-osi)
- [Las 7 capas](#las-7-capas)
- [Encapsulación y desencapsulación](#encapsulación-y-desencapsulación)
- [Dispositivos por capa](#dispositivos-por-capa)
- [Seguridad por capa](#seguridad-por-capa)
- [Troubleshooting](#troubleshooting)

---

## ¿Qué es el modelo OSI?

El modelo **OSI** (*Open Systems Interconnection*) es un marco conceptual de 7 capas que describe cómo los datos viajan de una aplicación en un dispositivo hasta la aplicación en otro dispositivo a través de una red.

Fue definido por la **ISO** en 1984. No es un protocolo en sí — es un modelo de referencia. Su valor principal es:

- **Estandarizar** cómo los fabricantes implementan hardware y software de red.
- **Facilitar el troubleshooting**: aislar en qué capa está el problema.
- **Educación**: entender cómo se construye la comunicación de red por capas.

---

## Las 7 capas

```
┌─────────────────────────────────────────────────────────────┐
│  7 │ APLICACIÓN      │ HTTP, FTP, DNS, SMTP, SNMP           │
├────┼─────────────────┼───────────────────────────────────────┤
│  6 │ PRESENTACIÓN    │ SSL/TLS, cifrado, compresión, JPEG   │
├────┼─────────────────┼───────────────────────────────────────┤
│  5 │ SESIÓN          │ NetBIOS, RPC, gestión de sesiones     │
├────┼─────────────────┼───────────────────────────────────────┤
│  4 │ TRANSPORTE      │ TCP, UDP — segmentos y datagramas     │
├────┼─────────────────┼───────────────────────────────────────┤
│  3 │ RED             │ IP, ICMP, routers — paquetes         │
├────┼─────────────────┼───────────────────────────────────────┤
│  2 │ ENLACE DE DATOS │ Ethernet, WiFi (802.11), switches    │
├────┼─────────────────┼───────────────────────────────────────┤
│  1 │ FÍSICA          │ Bits, cables, hubs, señales eléctricas│
└─────────────────────────────────────────────────────────────┘
```

> **Mnemotécnico** (de abajo hacia arriba): **P**or **F**avor **R**elájate **T**omando **S**oda **P**or **A**quí  
> Física → Enlace → Red → Transporte → Sesión → Presentación → Aplicación

---

### Capa 1 — Física

**Unidad**: Bits

Se ocupa de la **transmisión de bits** por el medio físico. Define:

- Voltajes y señales eléctricas / ópticas / de radio.
- Velocidad de transmisión (bps).
- Conectores físicos (RJ45, SFP, etc.).

**Dispositivos**: hubs, repetidores, cables, fibra óptica.

```
Problema típico en capa 1:
- Cable roto o mal terminado
- Interferencia electromagnética
- Distancia superada para el medio
```

---

### Capa 2 — Enlace de Datos

**Unidad**: Tramas (*frames*)

Gestiona la comunicación entre dispositivos en la **misma red local** (mismo segmento). Usa **direcciones MAC** (Media Access Control).

Subdivisiones:
- **LLC** (*Logical Link Control*): control de flujo y errores.
- **MAC** (*Media Access Control*): acceso al medio compartido.

**Dispositivos**: switches de capa 2, bridges.

```bash
# Ver la dirección MAC de tus interfaces
ip link show
# o
ifconfig -a | grep ether

# En Windows:
ipconfig /all | findstr "Physical"
```

**Formato de una trama Ethernet**:

```
| MAC destino (6B) | MAC origen (6B) | Tipo (2B) | Datos | FCS (4B) |
```

---

### Capa 3 — Red

**Unidad**: Paquetes

Responsable del **enrutamiento** entre redes distintas. Usa **direcciones IP**.

**Dispositivos**: routers, switches de capa 3.

**Protocolos clave**:

| Protocolo | Función                                        |
|-----------|------------------------------------------------|
| IPv4      | Direccionamiento de 32 bits                    |
| IPv6      | Direccionamiento de 128 bits                   |
| ICMP      | Mensajes de control (ping, traceroute)         |
| ARP       | Resuelve IP → MAC dentro de una LAN            |
| OSPF/BGP  | Protocolos de enrutamiento dinámico            |

```bash
# Ver tabla de enrutamiento
ip route show          # Linux
netstat -r             # Linux/macOS
route print            # Windows

# Ver correspondencias IP-MAC (tabla ARP)
arp -a
```

---

### Capa 4 — Transporte

**Unidad**: Segmentos (TCP) / Datagramas (UDP)

Garantiza (o no) la entrega de datos entre aplicaciones usando **puertos**.

| Protocolo | Conexión    | Confiabilidad | Velocidad | Uso típico                        |
|-----------|-------------|---------------|-----------|-----------------------------------|
| **TCP**   | Orientado   | Garantizada   | Menor     | HTTP, SSH, FTP, correo            |
| **UDP**   | Sin conexión| No garantizada| Mayor     | DNS, streaming, videojuegos, VoIP |

**Handshake de 3 vías (TCP)**:

```
Cliente          Servidor
   │──── SYN ────→│
   │←─ SYN-ACK ───│
   │──── ACK ────→│
   │   [conexión establecida]
```

```bash
# Ver conexiones TCP activas
ss -tuln              # Linux (reemplaza netstat)
netstat -an           # Linux/Windows/macOS

# Ver qué proceso usa qué puerto
ss -tulnp
lsof -i :443          # qué proceso usa el puerto 443
```

---

### Capa 5 — Sesión

**Unidad**: Datos

Establece, gestiona y termina **sesiones** entre aplicaciones.

**Ejemplos**: autenticación en NetBIOS, sesiones RPC, gestión de tokens de sesión en aplicaciones web.

Aunque el modelo OSI separa esta capa, en la práctica TCP/IP la fusiona con transporte y aplicación.

---

### Capa 6 — Presentación

**Unidad**: Datos

Se encarga de la **traducción, cifrado y compresión** de los datos.

- Convierte entre formatos (ASCII ↔ EBCDIC, UTF-8, etc.)
- Cifrado/descifrado: **SSL/TLS** opera en esta capa.
- Compresión de datos (gzip, deflate).

```bash
# Verificar un certificado TLS de un servidor
openssl s_client -connect google.com:443 -showcerts
# Muestra la cadena de certificados y la negociación TLS
```

---

### Capa 7 — Aplicación

**Unidad**: Datos

La capa más cercana al usuario. Provee **interfaces de comunicación** para las aplicaciones.

**Protocolos principales**:

| Protocolo | Puerto  | Función                          |
|-----------|---------|----------------------------------|
| HTTP      | 80      | Web sin cifrar                   |
| HTTPS     | 443     | Web cifrada (HTTP + TLS)         |
| FTP       | 20/21   | Transferencia de archivos        |
| SSH       | 22      | Acceso remoto seguro             |
| DNS       | 53      | Resolución de nombres a IPs      |
| SMTP      | 25/587  | Envío de correo                  |
| IMAP/POP3 | 143/110 | Recepción de correo              |
| SNMP      | 161     | Monitoreo de dispositivos de red |

---

## Encapsulación y desencapsulación

Cuando un mensaje viaja de una aplicación a otra, cada capa **agrega** su propio encabezado:

```
Aplicación     → [Datos]
Presentación   → [Datos]
Sesión         → [Datos]
Transporte     → [Header TCP/UDP][Datos]            ← Segmento
Red            → [Header IP][Header TCP/UDP][Datos]  ← Paquete
Enlace datos   → [Header MAC][Paquete][FCS]          ← Trama
Física         → 10110101011010...                   ← Bits
```

En el destino, el proceso es inverso: cada capa **desencapsula** su header.

---

## Dispositivos por capa

| Capa | Dispositivo                         | Opera sobre       |
|------|-------------------------------------|-------------------|
| 1    | Hub, repetidor, cable               | Bits              |
| 2    | Switch L2, bridge, AP               | MACs / Tramas     |
| 3    | Router, switch L3, firewall L3      | IPs / Paquetes    |
| 4-7  | Firewall de aplicación, proxy, IDS  | Conexiones / datos|

---

## Seguridad por capa

| Capa | Amenaza principal                     | Contramedida                         |
|------|---------------------------------------|--------------------------------------|
| 1    | Sniffing físico, corte de cable       | Seguridad física, fibra óptica       |
| 2    | ARP Spoofing, MAC flooding            | DAI (Dynamic ARP Inspection), port security |
| 3    | IP Spoofing, routing malicioso        | ACLs, ingress filtering              |
| 4    | SYN Flood, escaneo de puertos        | Firewall stateful, rate limiting     |
| 5-6  | Session hijacking, SSL stripping      | TLS actualizado, HSTS                |
| 7    | SQL injection, XSS, phishing          | WAF, validación de inputs, DNSSEC   |

```bash
# Detectar escaneo de puertos con nmap (en tu propia red)
nmap -sV -p 1-1000 192.168.1.1

# Ver si hay ARP spoofing en la red
arp -a
# Si ves dos IPs con la misma MAC → posible ARP spoofing
```

---

## Troubleshooting

### Metodología top-down vs bottom-up

**Bottom-up** (recomendado para problemas de conectividad total):

```
1. Capa 1: ¿Hay luz en el cable de red? ¿La interfaz está activa?
   → ip link show / ping local

2. Capa 2: ¿La MAC se resuelve correctamente?
   → arp -a

3. Capa 3: ¿Hay IP asignada? ¿El gateway responde?
   → ip addr / ping gateway

4. Capa 4: ¿El puerto de la aplicación está abierto?
   → telnet host puerto / nc -zv host puerto

5. Capa 7: ¿La aplicación responde?
   → curl -v http://host / wget
```

```bash
# Diagnóstico rápido capa a capa (Linux)

# Capa 1-2
ip link show eth0

# Capa 3
ip addr show eth0
ping -c 3 $(ip route | grep default | awk '{print $3}')

# Capa 4
nc -zv google.com 443
# Expected: Connection to google.com 443 port [tcp/https] succeeded!

# Capa 7
curl -sI https://google.com | head -5
```

---

## Siguiente módulo

→ [Módulo 4 — Modelo TCP/IP](modulo-4-modelo-tcp-ip.md)
