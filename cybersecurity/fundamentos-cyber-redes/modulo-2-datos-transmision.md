# Módulo 2 — Datos y Medios de Transmisión

## Contenido

- [Datos en una red](#datos-en-una-red)
- [Medios de transmisión](#medios-de-transmisión)
- [Rendimiento y ancho de banda](#rendimiento-y-ancho-de-banda)
- [Infraestructura de red](#infraestructura-de-red)
- [Estándares y canales WiFi](#estándares-y-canales-wifi)
- [Seguridad WiFi](#seguridad-wifi)
- [Troubleshooting](#troubleshooting)

---

## Datos en una red

Toda comunicación en una red es, en esencia, transmisión de **datos binarios** (bits).  
Esos bits se organizan en:

```
Bit → Byte → Segmento (TCP) / Datagrama (UDP) → Paquete (IP) → Trama (Ethernet)
```

Cada capa del modelo OSI/TCP-IP agrega su propio encabezado (*header*) al bloque de datos — proceso llamado **encapsulación**.

---

## Medios de transmisión

### Cable de cobre (UTP)

El medio más común en redes LAN. Transmite datos mediante señales eléctricas.

| Categoría | Velocidad máxima | Frecuencia | Uso típico              |
|-----------|-----------------|------------|-------------------------|
| Cat5e     | 1 Gbps          | 100 MHz    | Redes domésticas        |
| Cat6      | 10 Gbps (55 m)  | 250 MHz    | Oficinas                |
| Cat6a     | 10 Gbps (100 m) | 500 MHz    | Data centers            |
| Cat8      | 40 Gbps         | 2000 MHz   | Data centers de alta densidad |

**Problema principal**: susceptible a interferencias electromagnéticas (EMI) y limitado en distancia (~100 m por segmento).

### Fibra óptica

Transmite datos mediante pulsos de luz. Sin interferencia electromagnética.

| Tipo           | Distancia         | Uso                            |
|----------------|-------------------|--------------------------------|
| Multimodo (OM) | Hasta 550 m       | Dentro de edificios            |
| Monomodo (OS)  | Hasta 80 km+      | Conexiones entre edificios/ISP |

```bash
# Ver velocidad de interfaz de red en Linux
ethtool eth0 | grep Speed
# Speed: 1000Mb/s  ← indica Gigabit Ethernet
```

### Medios inalámbricos

Transmiten datos mediante ondas de radio o infrarrojas.

| Tecnología | Banda       | Rango típico | Velocidad teórica |
|------------|-------------|--------------|-------------------|
| WiFi 4 (n) | 2.4 / 5 GHz | ~50 m        | 600 Mbps          |
| WiFi 5 (ac)| 5 GHz       | ~35 m        | 3.5 Gbps          |
| WiFi 6 (ax)| 2.4 / 5 GHz | ~50 m        | 9.6 Gbps          |
| Bluetooth  | 2.4 GHz     | ~10 m        | 3 Mbps            |

---

## Rendimiento y ancho de banda

### Ancho de banda

Capacidad máxima del canal de transmisión. Se mide en **bps** (bits por segundo).

```
1 Mbps  = 1,000,000 bps
1 Gbps  = 1,000,000,000 bps
```

> **Importante**: el ancho de banda contratado con el ISP es el máximo teórico. El rendimiento real siempre es menor.

### Throughput (rendimiento real)

El rendimiento efectivo que se obtiene en la práctica, afectado por:

- Congestión de red
- Calidad del medio de transmisión
- Protocolos de control de errores
- Número de usuarios simultáneos

```bash
# Medir throughput entre dos hosts (requiere iperf3 en ambos lados)

# En el servidor:
iperf3 -s

# En el cliente:
iperf3 -c 192.168.1.100 -t 30
# -t 30: prueba de 30 segundos
```

### Cálculo práctico de tiempo de transferencia

```
Tiempo (s) = Tamaño del archivo (bits) / Ancho de banda (bps)

Ejemplo: archivo de 100 MB en una conexión de 10 Mbps
100 MB = 800,000,000 bits
Tiempo = 800,000,000 / 10,000,000 = 80 segundos
```

---

## Infraestructura de red

Una red completa requiere tres capas de hardware:

```
┌─────────────────────────────────────────────────────┐
│              CAPA DE ACCESO                         │
│  Switches L2 · Access Points · Cables UTP           │
├─────────────────────────────────────────────────────┤
│              CAPA DE DISTRIBUCIÓN                   │
│  Switches L3 · Firewalls · Routers internos         │
├─────────────────────────────────────────────────────┤
│              CAPA NÚCLEO (CORE)                     │
│  Routers WAN · Fibra de alta velocidad · Internet   │
└─────────────────────────────────────────────────────┘
```

Este diseño de **3 capas** (acceso, distribución, núcleo) es el estándar en redes empresariales porque facilita la escalabilidad y el troubleshooting.

---

## Estándares y canales WiFi

### Estándares IEEE 802.11

El organismo **IEEE** define los estándares para WiFi bajo la familia 802.11:

| Estándar   | Año  | Banda        | Velocidad máx. | Nombre comercial |
|------------|------|--------------|----------------|------------------|
| 802.11b    | 1999 | 2.4 GHz      | 11 Mbps        | WiFi 1           |
| 802.11a    | 1999 | 5 GHz        | 54 Mbps        | WiFi 2           |
| 802.11g    | 2003 | 2.4 GHz      | 54 Mbps        | WiFi 3           |
| 802.11n    | 2009 | 2.4/5 GHz    | 600 Mbps       | WiFi 4           |
| 802.11ac   | 2013 | 5 GHz        | 3.5 Gbps       | WiFi 5           |
| 802.11ax   | 2019 | 2.4/5/6 GHz  | 9.6 Gbps       | WiFi 6/6E        |

### Canales en 2.4 GHz

En 2.4 GHz hay 13 canales (en América Latina), pero solo **3 no se superponen**: 1, 6 y 11.

```
Canal:  1    2    3    4    5    6    7    8    9   10   11
        [====1====]
                  [====2====]        ← se superpone
                            [====6====]
                                          [====11====]

Configuración óptima para 3 APs en el mismo espacio:
  AP1 → Canal 1
  AP2 → Canal 6
  AP3 → Canal 11
```

En **5 GHz** hay más canales sin superposición, lo que reduce la interferencia.

---

## Seguridad WiFi

### Protocolos de seguridad WiFi (evolución)

| Protocolo | Año  | Estado        | Vulnerabilidades conocidas            |
|-----------|------|---------------|---------------------------------------|
| WEP       | 1997 | **Obsoleto**  | Rompible en minutos con herramientas  |
| WPA       | 2003 | Deprecated    | TKIP vulnerable a ataques de replay   |
| WPA2      | 2004 | Aceptable     | Vulnerable a KRACK, diccionario PSK   |
| WPA3      | 2018 | **Recomendado**| SAE resiste ataques de diccionario   |

### Vulnerabilidades WiFi principales

**1. Ataques de diccionario / fuerza bruta (WPA2-PSK)**

Si la contraseña es débil, puede capturarse el *handshake* y crackearse offline.

```bash
# Ejemplo conceptual (entorno controlado / CTF):
# Captura de handshake con airodump-ng
# Crackeo con hashcat o aircrack-ng
# NUNCA usar en redes ajenas — es ilegal.
```

**2. Evil Twin Attack**

Un atacante crea un AP con el mismo SSID y mayor potencia. Los clientes se conectan al AP falso.

```
Víctima ──────────────────→ [AP falso "CaféWiFi"] → Atacante captura tráfico
            (más señal)
```

**3. KRACK (Key Reinstallation Attack)**

Vulnerabilidad en el handshake de 4 vías de WPA2. Parcheada en la mayoría de dispositivos modernos.

### Mitigaciones recomendadas

```
✅ Usar WPA3 (o WPA2-AES si WPA3 no está disponible)
✅ Contraseña de al menos 20 caracteres, aleatoria
✅ Deshabilitar WPS (vulnerable a ataques de PIN)
✅ Usar VPN en redes WiFi públicas
✅ Actualizar el firmware del router regularmente
✅ Segmentar la red: VLAN para invitados, VLAN para IoT
✅ Desactivar SSID broadcast en redes sensibles (oscuridad ≠ seguridad, pero reduce exposición)
```

---

## Troubleshooting

### Problema: velocidad WiFi lenta

```bash
# 1. Ver canales WiFi disponibles y saturación (Linux)
sudo iwlist wlan0 scan | grep -E "ESSID|Channel|Quality"

# 2. Ver en qué canal está tu AP
iwconfig wlan0

# 3. Medir velocidad real de conexión
iperf3 -c 192.168.1.1 -t 10

# 4. Windows — ver detalles de adaptador WiFi
netsh wlan show interfaces
netsh wlan show networks mode=bssid
```

### Problema: interferencias en 2.4 GHz

- Cambiar el canal del AP a 1, 6 o 11 (evitar "auto" si hay vecinos).
- Considerar migrar a 5 GHz si los dispositivos lo soportan.

### Herramienta recomendada para diagnóstico WiFi

- **Linux**: `wavemon`, `nmtui`, `iw`
- **Windows**: `netsh wlan`, WiFi Analyzer (Microsoft Store)
- **Android/iOS**: WiFi Analyzer (app gratuita)

---

## Siguiente módulo

→ [Módulo 3 — Modelo OSI](modulo-3-modelo-osi.md)
