# Módulo 1 — Importancia de las Redes

## Contenido

- [Concepto de red](#concepto-de-red)
- [Terminología esencial](#terminología-esencial)
- [Tipos de redes](#tipos-de-redes)
- [Topologías de red](#topologías-de-red)
- [Equipos de red](#equipos-de-red)
- [Red cableada vs Red WiFi](#red-cableada-vs-red-wifi)
- [Seguridad](#seguridad)
- [Troubleshooting](#troubleshooting)

---

## Concepto de red

Una **red** es la infraestructura tecnológica que permite que computadoras y dispositivos envíen y reciban datos entre sí.

Sin redes no existiría internet, las redes sociales, el trabajo remoto ni las videoconferencias. Son la base de prácticamente toda la tecnología moderna.

---

## Terminología esencial

### Protocolo

Conjunto de **reglas** que los dispositivos deben respetar para comunicarse. Si dos dispositivos no hablan el mismo protocolo, no pueden intercambiar información — igual que dos personas que hablan idiomas distintos.

**Ejemplos de protocolos**: HTTP, HTTPS, TCP, UDP, IP, FTP.

### Paquete

Los datos no se envían de una sola vez. Se dividen en **paquetes** más pequeños para:

- Transmitirlos de forma eficiente.
- Detectar y reenviar los que se pierden.
- Reensamblarlos en el destino en el orden correcto.

```
Archivo de 1 GB
    └── Paquete 1 (fragmento)
    └── Paquete 2 (fragmento)
    └── ...
    └── Paquete N (fragmento)
         → Destino reensambla los N paquetes
```

### Nodo

Cualquier **dispositivo conectado a una red**. Puede ser una computadora, un servidor, una impresora de red, un celular, etc.

### Puertos

Hay dos tipos:

| Tipo           | Descripción                                                                 |
|----------------|-----------------------------------------------------------------------------|
| **Físico**     | El conector donde se enchufa el cable o la antena WiFi                      |
| **Lógico**     | Permite múltiples conexiones simultáneas sobre una sola interfaz física     |

**Ejemplo de puertos lógicos comunes**:

| Puerto | Protocolo / Servicio |
|--------|----------------------|
| 22     | SSH                  |
| 80     | HTTP                 |
| 443    | HTTPS                |
| 3306   | MySQL                |
| 3389   | RDP                  |

### Latencia

Tiempo que tarda un paquete en ir de origen a destino.

```
Latencia baja  → conexión rápida (deseable)
Latencia alta  → conexión lenta (problemas de red o distancia geográfica)
```

Podés medirla con:

```bash
ping google.com
# PING google.com (142.250.x.x): 56 bytes
# 64 bytes from ...: icmp_seq=0 ttl=118 time=14.3 ms  ← latencia
```

---

## Tipos de redes

| Sigla  | Nombre completo                  | Descripción                                                     |
|--------|----------------------------------|-----------------------------------------------------------------|
| LAN    | Local Area Network               | Red doméstica u oficina. Espacio geográfico pequeño.            |
| WLAN   | Wireless Local Area Network      | LAN pero vía WiFi (sin cables).                                 |
| WAN    | Wide Area Network                | Interconexión de múltiples LANs. Internet es una WAN global.    |
| VLAN   | Virtual Local Area Network       | Red lógica/virtual creada mediante software sobre hardware físico. |

### Ejemplo práctico — WAN

```
Casa A (LAN) ──── Router A ──┐
                              ├──── Internet (WAN) ──── Servidor remoto
Oficina B (LAN) ── Router B ──┘
```

---

## Topologías de red

La **topología** define cómo están físicamente o lógicamente conectados los nodos.

| Topología       | Descripción                                                      | Pros                          | Contras                              |
|-----------------|------------------------------------------------------------------|-------------------------------|--------------------------------------|
| **Bus**         | Todos los nodos comparten un único cable central                 | Simple, económico             | Si el cable falla, cae toda la red   |
| **Anillo**      | Cada nodo conectado al siguiente formando un círculo             | Flujo ordenado                | Un nodo caído puede romper el anillo |
| **Estrella**    | Todos los nodos conectados a un switch/hub central               | Fácil de gestionar            | El switch central es punto de fallo  |
| **Doble anillo**| Dos anillos redundantes                                          | Alta disponibilidad           | Más costo y complejidad              |
| **Árbol**       | Jerarquía de nodos (estrella de estrellas)                       | Escalable                     | Dependencia del nodo raíz            |
| **Malla**       | Cada nodo conectado a múltiples nodos                            | Muy resiliente                | Costoso y complejo de mantener       |
| **Mixta**       | Combinación de topologías                                        | Flexible                      | Compleja de diseñar                  |

**La más usada hoy en redes modernas**: **Estrella** (en LAN) y **Malla parcial** (en WAN/Internet).

---

## Equipos de red

La infraestructura de red se divide en tres categorías:

### 1. Dispositivos finales (*End Devices*)

Son los que generan o consumen los datos:

- Computadoras de escritorio y laptops
- Impresoras de red
- Teléfonos IP
- Tablets y smartphones
- Cámaras IP

### 2. Dispositivos intermedios

Gestionan el tráfico entre dispositivos finales:

| Dispositivo            | Función                                                                |
|------------------------|------------------------------------------------------------------------|
| **Router**             | Enruta paquetes entre redes distintas (LAN ↔ WAN)                    |
| **Switch (LAN)**       | Conecta dispositivos dentro de la misma red local                      |
| **Switch multicapa**   | Combina funciones de switch y router                                   |
| **Access Point (AP)**  | Extiende la red mediante WiFi                                          |
| **Firewall**           | Filtra tráfico según reglas de seguridad                               |
| **Wireless Router**    | Router con AP integrado (el típico router doméstico)                  |

### 3. Medios de red

El canal por donde viajan los datos:

| Medio              | Tipo        | Ejemplo                   |
|--------------------|-------------|---------------------------|
| Cable de cobre     | Cableado    | UTP Cat5e, Cat6           |
| Fibra óptica       | Cableado    | Redes de alta velocidad   |
| Señal de radio     | Inalámbrico | WiFi 2.4 GHz / 5 GHz     |
| Infrarrojo         | Inalámbrico | Transferencia corta        |

---

## Red cableada vs Red WiFi

| Característica      | Red cableada (Ethernet)              | Red WiFi (WLAN)                        |
|---------------------|--------------------------------------|----------------------------------------|
| **Velocidad**       | Alta y estable                       | Variable según distancia e interferencias |
| **Latencia**        | Baja                                 | Mayor que cableado                     |
| **Seguridad**       | Alta (requiere acceso físico)        | Menor (señal viaja por el aire)        |
| **Instalación**     | Compleja (cables, ductos)            | Simple                                 |
| **Movilidad**       | Fija                                 | Alta                                   |
| **Interferencias**  | Prácticamente ninguna                | Paredes, otros dispositivos, frecuencias|
| **Costo inicial**   | Mayor (cableado)                     | Menor                                  |
| **Ideal para**      | Desktops, consolas, servidores       | Laptops, celulares, IoT                |

---

## Seguridad

### Riesgos en redes cableadas

- **Acceso físico no autorizado**: si alguien enchufa un dispositivo al switch, está en la red.
- **Mitigación**: control de acceso a salas de servidores, seguridad de puertos en el switch (`port security`).

```bash
# Ejemplo Cisco IOS — habilitar port security en un switch
Switch(config)# interface FastEthernet0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport port-security
Switch(config-if)# switchport port-security maximum 1
Switch(config-if)# switchport port-security violation shutdown
```

### Riesgos en redes WiFi

- **Redes abiertas**: cualquiera puede conectarse y capturar tráfico.
- **Evil Twin**: un atacante crea un AP con el mismo SSID para capturar credenciales.
- **Mitigación básica**: usar WPA3, SSID no publicitado, segmentación con VLANs.

> ⚠️ **Regla de oro**: nunca conectarse a redes WiFi públicas sin una VPN activa.

---

## Troubleshooting

### Problema: no hay conectividad de red

```bash
# 1. Verificar si la interfaz está activa
ip link show
# o en Windows:
ipconfig /all

# 2. Verificar IP asignada
ip addr show
# o en Windows:
ipconfig

# 3. Probar conectividad al gateway (router)
ping 192.168.1.1   # cambiá por el IP de tu gateway

# 4. Probar resolución DNS
ping google.com
nslookup google.com

# 5. Trazar la ruta hasta el destino
traceroute google.com   # Linux/macOS
tracert google.com      # Windows
```

### Problema: alta latencia

```bash
# Medir latencia continua
ping -c 20 google.com   # Linux/macOS (20 paquetes)
ping -n 20 google.com   # Windows

# Identificar en qué salto está el cuello de botella
traceroute google.com
```

### Problema: no resuelve nombres DNS

```bash
# Cambiar DNS temporalmente (Linux)
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Limpiar caché DNS (Windows)
ipconfig /flushdns

# Probar con DNS alternativo
nslookup google.com 8.8.8.8
```

---

## Siguiente módulo

→ [Módulo 2 — Datos y Medios de Transmisión](modulo-2-datos-transmision.md)
