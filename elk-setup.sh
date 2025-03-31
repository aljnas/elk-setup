#!/bin/bash

# Verificar si jq está instalado
if ! command -v jq &> /dev/null; then
  echo '❗ El script requiere jq. Instalando...'
  sudo apt install -y jq
fi

echo "🔧 Instalando ELK Stack (Elasticsearch, Kibana, Filebeat) en Kali..."

KEYRING_PATH="/usr/share/keyrings/elasticsearch-keyring.gpg"
REPO_PATH="/etc/apt/sources.list.d/elastic-8.x.list"

if [ ! -f "$KEYRING_PATH" ]; then
    echo "🔐 Agregando clave GPG de Elasticsearch..."
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o "$KEYRING_PATH"
fi

if [ ! -f "$REPO_PATH" ]; then
    echo "📦 Agregando repositorio Elastic 8.x..."
    echo "deb [signed-by=$KEYRING_PATH] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee "$REPO_PATH"
fi

echo "🔄 Actualizando repositorios..."
sudo apt update

echo "📥 Instalando paquetes..."
if ! sudo apt install -y elasticsearch kibana filebeat; then
  echo "❌ Error al instalar paquetes. Abortando."
  exit 1
fi

echo "🚀 Habilitando y arrancando servicios..."
sudo systemctl enable --now elasticsearch
sudo systemctl enable --now kibana
sudo systemctl enable --now filebeat

echo "🛠️ Configurando Filebeat para monitorear /var/log/auth.log..."
sudo sed -i 's|#- type: log|- type: log|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#  enabled: true|  enabled: true|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#  paths:|  paths:|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#    - /var/log/*.log|    - /var/log/auth.log|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#output.elasticsearch:|output.elasticsearch:|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#  hosts: \["localhost:9200"\]|  hosts: ["localhost:9200"]|' /etc/filebeat/filebeat.yml

if systemctl is-active --quiet filebeat; then
  echo "🔁 Reiniciando Filebeat..."
  sudo systemctl restart filebeat
fi

echo "🧠 Esperando que Kibana esté listo..."
until curl -s http://localhost:5601 > /dev/null; do
  echo "⏳ Esperando que Kibana esté listo..."
  sleep 5
done

echo "📡 Creando índice 'filebeat-*' en Kibana..."
curl -X POST "http://localhost:5601/api/saved_objects/index-pattern/filebeat-*"   -H 'kbn-xsrf: true'   -H 'Content-Type: application/json'   -d '{"attributes":{"title":"filebeat-*","timeFieldName":"@timestamp"}}'

# El resto del script continuaría aquí...
