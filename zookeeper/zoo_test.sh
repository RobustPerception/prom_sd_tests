#!/bin/bash

# Assume ZooKeeper is installed on the test box.

# Create znode and add relevant target data.
/usr/share/zookeeper/bin/zkCli.sh -server localhost:2181 <<EOF
create /demo some_value
create /demo/key1 '{ "serviceEndpoint": {"host": "127.0.0.1", "port": 9090}, "status":"grand", "shard":1  }'
quit
EOF

# Download, untar, configure, and run Prometheus.
wget -q https://github.com/prometheus/prometheus/releases/download/v2.0.0/prometheus-2.0.0.linux-amd64.tar.gz
tar xzf prometheus-2.0.0.linux-amd64.tar.gz
cd prometheus-2.0.0.linux-amd64
cat << EOF > prometheus.yml
global:
  scrape_interval: 1s
scrape_configs:
  - job_name: 'zookeeper'
    serverset_sd_configs:
      - servers:
          - 'localhost:2181'
        paths:
          - '/demo'
EOF
./prometheus &

# Query Prometheus to see if expected target is found.
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[0].discoveredLabels.job'
res=`curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[0].discoveredLabels.job'`
if [ $res = 'zookeeper' ]; then
    exit 0
fi
exit 1
