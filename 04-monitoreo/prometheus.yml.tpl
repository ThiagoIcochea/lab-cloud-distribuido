global: { scrape_interval: 15s, evaluation_interval: 15s }
scrape_configs:
  - job_name: prometheus
    static_configs: [ { targets: [ "localhost:9090" ] } ]
  - job_name: nodo
    static_configs: [ { targets: [ "node-exporter:9100" ], labels: { nube: "gcp" } } ]
  # Sonda HTTP al servicio web del Lab 3. Se agregarían aquí endpoints de AWS, Azure o la nube privada.
  - job_name: servicio-web
    metrics_path: /probe
    params: { module: [ http_2xx ] }
    static_configs: [ { targets: [ "http://WEB_IP/" ], labels: { nube: "gcp" } } ]
    relabel_configs:
      - { source_labels: [ __address__ ], target_label: __param_target }
      - { source_labels: [ __param_target ], target_label: instance }
      - { target_label: __address__, replacement: "blackbox:9115" }
