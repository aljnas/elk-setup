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
git clone git@github.com:aljinas/elk-setup.git
cd elk-setup

