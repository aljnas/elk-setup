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
sudo apt install -y elasticsearch kibana filebeat

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
sudo sed -i 's|#  hosts: \["localhost:9200"\]|  hosts: \["localhost:9200"\]|' /etc/filebeat/filebeat.yml

echo "🔁 Reiniciando Filebeat..."
sudo systemctl restart filebeat

echo "🧠 Esperando 30 segundos para que Kibana termine de iniciar..."
sleep 30

echo "📡 Creando índice 'filebeat-*' en Kibana..."
curl -X POST "http://localhost:5601/api/saved_objects/index-pattern/filebeat-*" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{"attributes":{"title":"filebeat-*","timeFieldName":"@timestamp"}}'

echo "🔍 Creando búsqueda guardada 'Intentos fallidos SSH'..."
curl -X POST "http://localhost:5601/api/saved_objects/search/ssh-fails" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{
  "attributes": {
    "title": "Intentos fallidos SSH",
    "description": "Búsqueda rápida de intentos fallidos por SSH",
    "columns": ["message", "host.name", "source.ip"],
    "sort": ["@timestamp", "desc"],
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"language\":\"kuery\",\"query\":\"message : \\\"Failed password\\\"\"},\"filter\":[]}"
    }
  }
}'

echo "📊 Creando dashboard básico 'Seguridad SSH'..."
curl -X POST "http://localhost:5601/api/saved_objects/dashboard/seguridad-ssh" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{
  "attributes": {
    "title": "Seguridad SSH",
    "description": "Panel para monitorear accesos por SSH",
    "panelsJSON": "[]"
  }
}'

echo "📊 Creando visualizaciones..."
VIS1_ID=$(curl -s -X POST "http://localhost:5601/api/saved_objects/visualization/ssh-fails-by-hour" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{
  "attributes": {
    "title": "SSH Fails por Hora",
    "visState": "{\"title\":\"SSH Fails por Hora\",\"type\":\"histogram\",\"params\":{\"type\":\"histogram\",\"addLegend\":true},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\"},{\"id\":\"2\",\"type\":\"date_histogram\",\"schema\":\"segment\",\"params\":{\"field\":\"@timestamp\",\"interval\":\"auto\"}}]}",
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"language\":\"kuery\",\"query\":\"message : \\\"Failed password\\\"\"}}"
    }
  }
}' | jq -r '.id')

VIS2_ID=$(curl -s -X POST "http://localhost:5601/api/saved_objects/visualization/top-ips" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{
  "attributes": {
    "title": "Top IPs SSH",
    "visState": "{\"title\":\"Top IPs SSH\",\"type\":\"table\",\"params\":{\"perPage\":10},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\"},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"source.ip\",\"size\":10}}]}",
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"language\":\"kuery\",\"query\":\"message : \\\"Failed password\\\"\"}}"
    }
  }
}' | jq -r '.id')

VIS3_ID=$(curl -s -X POST "http://localhost:5601/api/saved_objects/visualization/target-users" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{
  "attributes": {
    "title": "Usuarios SSH Atacados",
    "visState": "{\"title\":\"Usuarios SSH Atacados\",\"type\":\"table\",\"params\":{\"perPage\":10},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\"},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"user.name\",\"size\":10}}]}",
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"index\":\"filebeat-*\",\"query\":{\"language\":\"kuery\",\"query\":\"message : \\\"Failed password\\\"\"}}"
    }
  }
}' | jq -r '.id')

PANEL_JSON=$(cat <<EOF
[
  {
    "panelIndex": "1",
    "gridData": { "x": 0, "y": 0, "w": 24, "h": 15, "i": "1" },
    "type": "visualization",
    "id": "$VIS1_ID"
  },
  {
    "panelIndex": "2",
    "gridData": { "x": 0, "y": 15, "w": 12, "h": 10, "i": "2" },
    "type": "visualization",
    "id": "$VIS2_ID"
  },
  {
    "panelIndex": "3",
    "gridData": { "x": 12, "y": 15, "w": 12, "h": 10, "i": "3" },
    "type": "visualization",
    "id": "$VIS3_ID"
  }
]
EOF
)

curl -X PUT "http://localhost:5601/api/saved_objects/dashboard/seguridad-ssh"   -H 'kbn-xsrf: true' -H 'Content-Type: application/json'   -d "{
    "attributes": {
      "title": "Seguridad SSH",
      "panelsJSON": $PANEL_JSON,
      "optionsJSON": "{}" 
    }
  }"

echo "✅ Dashboard 'Seguridad SSH' con visualizaciones cargado. Ve a http://localhost:5601 para verlo."
