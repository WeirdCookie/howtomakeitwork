/home/ole/
├── repo/                          # Git Clone deines Repos
│   ├── .github/workflows/deploy.yml
│   ├── tools/
│   │   ├── rust-tool/             # Rust Microservice
│   │   ├── python-tool/           # Python Microservice
│   │   ├── nim-tool/              # Nim Microservice
│   │   ├── c-tool/                # C Microservice
│   │   ├── ruby-tool/             # Ruby Microservice (Podman)
│   │   └── ...
│   ├── wiki/                      # Statische Wiki-Seiten
│   ├── Caddyfile                  # Reverse Proxy Config
│   └── deploy.sh                  # Deploy-Script
├── containers/                    # Podman Quadlet-Dateien
│   └── systemd/
│       └── user/
│           ├── python-tool.container
│           ├── ruby-tool.container
│           └── ...
├── services/                      # Systemd Services für kompilierte Sprachen
│   └── rust-tool.service
└── data/                          # Persistente Daten
    └── tools/