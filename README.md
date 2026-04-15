# SMTP Relay – Stalwart MTA via Docker

Vollständige Einrichtung eines SMTP-Relay-Servers mit [Stalwart Mail Server](https://stalw.art) auf einem Linux-Server via Docker.

---

## Projektstruktur

```
smtprelay/
├── docker-compose.yml       # Container-Orchestrierung
├── Dockerfile               # Eigenes Image (optional)
├── .env.example             # Vorlage für Umgebungsvariablen
├── .env                     # Lokale Konfiguration (nicht einchecken!)
├── .gitignore
├── config/
│   ├── config.toml          # Stalwart Hauptkonfiguration
│   └── tls/                 # TLS-Zertifikate (nicht einchecken!)
│       ├── tls.crt
│       └── tls.key
├── data/                    # Persistente Serverdaten (nicht einchecken!)
│   ├── queue/               # Mail-Queue
│   └── logs/
└── scripts/
    └── setup.sh             # Einmaliges Setup-Skript für Linux
```

---

## Schritt-für-Schritt: Linux-Server einrichten

### 1. Docker installieren (Debian/Ubuntu)

```bash
# Schnellinstallation via offiziellem Skript
curl -fsSL https://get.docker.com | sudo bash

# Docker ohne sudo nutzen (optional, danach ausloggen + einloggen)
sudo usermod -aG docker $USER

# Versions-Check
docker --version
docker compose version
```

### 2. Projekt vom GitHub holen

```bash
# Repository klonen
git clone https://github.com/DEIN-USER/smtprelay.git
cd smtprelay

# ODER: Wenn Repo schon vorhanden → aktualisieren
git pull origin main
```

### 3. Erstkonfiguration ausführen

```bash
# Setup-Skript ausführbar machen und starten
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

Das Skript erledigt automatisch:
- Docker + Docker Compose Plugin installieren
- Verzeichnisstruktur (`data/`, `config/tls/`) anlegen
- `.env` aus `.env.example` erzeugen
- Firewall-Ports freigeben (ufw)

### 4. Umgebungsvariablen anpassen

```bash
nano .env
```

Wichtige Werte:
| Variable | Beschreibung | Beispiel |
|----------|-------------|---------|
| `MAIL_HOSTNAME` | FQDN des Servers | `mail.example.com` |
| `ADMIN_SECRET` | Admin-Passwort (Web UI) | starkes Passwort |
| `SMTP_SMARTHOST` | Weiterleitungs-SMTP (optional) | leer = direkt |
| `TIMEZONE` | Zeitzone | `Europe/Berlin` |

---

## Docker-Befehle

### Starten

```bash
# Container im Hintergrund starten
docker compose up -d

# ODER: Mit eigenem Dockerfile bauen + starten
docker compose up -d --build
```

### Logs

```bash
# Live-Logs verfolgen
docker compose logs -f stalwart

# Letzte 100 Zeilen
docker compose logs --tail=100 stalwart
```

### Status

```bash
# Container-Status prüfen
docker compose ps

# Ressourcenverbrauch
docker stats stalwart-smtp-relay
```

### Stoppen / Neustarten

```bash
# Stoppen
docker compose stop

# Stoppen + Container entfernen (Daten bleiben erhalten)
docker compose down

# Neustarten
docker compose restart stalwart
```

### Konfiguration neu laden

```bash
# Nach Änderungen in config/config.toml
docker compose restart stalwart
```

### Update (neues Image)

```bash
docker compose pull
docker compose up -d
```

---

## Admin-Interface

Nach dem Start erreichbar unter:

```
http://<SERVER-IP>:8080
```

Login: `admin` / Wert aus `ADMIN_SECRET` in `.env`

---

## Port-Übersicht

| Port | Protokoll | Verwendung |
|------|-----------|------------|
| `25` | SMTP | Eingehend (MTA-to-MTA) |
| `587` | SMTP + STARTTLS | Client-Submission (mit Auth) |
| `465` | SMTPS | Client-Submission (TLS direkt) |
| `8080` | HTTP | Web Admin |

---

## Verbindung testen

```bash
# SMTP Verbindung testen (vom Server aus)
telnet localhost 25

# SMTP mit AUTH testen (swaks installieren)
swaks --to test@example.com \
      --from relay@example.com \
      --server localhost:587 \
      --auth-user admin \
      --auth-password changeme \
      --tls

# Alternativ: openssl
openssl s_client -starttls smtp -connect localhost:587
```

---

## Firewall (ufw)

```bash
# Manuell Ports öffnen
sudo ufw allow 25/tcp
sudo ufw allow 587/tcp
sudo ufw allow 465/tcp
sudo ufw allow 8080/tcp
sudo ufw status
```

---

## Troubleshooting

```bash
# In laufenden Container einsteigen
docker exec -it stalwart-smtp-relay /bin/sh

# Konfiguration auf Syntax prüfen
docker exec stalwart-smtp-relay stalwart-mail --config /opt/stalwart-mail/etc/config.toml --check

# Queue anzeigen
docker exec stalwart-smtp-relay stalwart-mail queue list

# Einzelne Mail aus Queue entfernen
docker exec stalwart-smtp-relay stalwart-mail queue delete <MESSAGE-ID>
```

---

## GitHub Workflow (Dev → Server)

```bash
# Lokal (Windows): Änderungen pushen
git add .
git commit -m "feat: Konfiguration anpassen"
git push origin main

# Auf dem Linux-Server: Änderungen holen + neu starten
git pull origin main
docker compose restart stalwart
```

---

## Links

- [Stalwart Dokumentation](https://stalw.art/docs/get-started/)
- [Stalwart GitHub](https://github.com/stalwartlabs/mail-server)
- [Docker Dokumentation](https://docs.docker.com/)
