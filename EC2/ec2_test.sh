#!/bin/bash

set -ex

go get github.com/prometheus/prometheus/cmd/...
make build
cat << EOF > prometheus.yml
global:
  scrape_interval: 1s
  evaluation_interval: 1s

scrape_configs:
  - job_name: 'node'
    ec2_sd_configs:
      - region: eu-west-1
        access_key: $AWS_ACCESS_KEY_ID 
        secret_key: $AWS_SECRET_ACCESS_KEY
        port: 9100
EOF
./prometheus &
sleep 10

res=`curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[0].discoveredLabels.__meta_ec2_public_dns_name'`
if [[ $res =~ "ec2" ]]; then
    pkill prometheus
    exit 0
fi
pkill prometheus
exit 1
