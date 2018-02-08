#!/bin/bash

set -ex

# Download, configure, and run Consul.
wget -q https://releases.hashicorp.com/consul/1.0.3/consul_1.0.3_linux_amd64.zip
unzip consul_*
echo '{"service": {"name": "web", "tags": ["web"], "port": 9090}}' | tee web.json
./consul agent -dev -config-dir=. &


# Build and run Prometheus.
go get github.com/prometheus/prometheus/cmd/...
make build
cat << EOF > prometheus.yml
global:
  scrape_interval: 1s

scrape_configs:
  - job_name: dummy
    consul_sd_configs:
      - server: 'localhost:8500'
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*,web,.*
        action: keep
      - source_labels: [__meta_consul_service]
        target_label: job
EOF
./prometheus &
sleep 10

# Check if Consul SD is working correctly.
res=`curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[0].health'`
if [[ $res = "up"  ]]; then
  kill -9 $!
  exit 0
fi
kill -9 $!
exit 1
