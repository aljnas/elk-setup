# ELK Setup Script 🔍

Script automatizado para instalar y configurar la pila **ELK (Elasticsearch, Kibana, Filebeat)** en sistemas Kali/Debian. Ideal para análisis de logs y monitoreo de seguridad SSH.

---

## 📦 ¿Qué hace este script?

- Instala Elasticsearch, Kibana y Filebeat
- Configura Filebeat para leer `/var/log/auth.log`
- Crea automáticamente:
  - Índice `filebeat-*` en Kibana
  - Búsqueda: `Intentos fallidos SSH`
  - Dashboard: `Seguridad SSH`
  - Visualizaciones: intentos por hora, IPs más activas y usuarios objetivo

---

## 🚀 ¿Cómo usarlo?

1. Clona este repositorio:
```bash
git clone git@github.com:aljnas/elk-setup.git
cd elk-setup
```

2. Dale permisos al script:
```bash
chmod +x elk-setup.sh
```

3. Ejecuta:
```bash
./elk-setup.sh
```

---

## 🔒 Requisitos

- Kali o Debian actualizado
- Acceso sudo
- Conexión a Internet
- Kibana activo en `http://localhost:5601`

---

## 🧠 Resultado esperado

Un dashboard llamado **Seguridad SSH** con visualizaciones como:

- 📊 Gráfico: intentos fallidos por hora
- 🌐 Tabla: top IPs atacantes
- 👤 Tabla: usuarios objetivo

---

## 🎨 Logo

![ELK Setup Logo](assets/elk-setup-logo.png)

---

## 📃 Licencia

MIT © [aljnas](https://github.com/aljnas)
