# SMTP Relay – Stalwart via Docker

SMTP-Relay-Server mit [Stalwart Mail Server](https://stalw.art) auf Linux via Docker.
Konfiguration erfolgt über das **Web-Interface** – nicht über manuelle Config-Dateien.

---

## Projektstruktur

```
smtprelay/
├── docker-compose.yml       # Container-Orchestrierung
├── Dockerfile               # Eigenes Image (optional, nur bei Anpassungen)
├── .env.example             # Vorlage für Umgebungsvariablen
├── .gitignore
├── scripts/
│   └── setup.sh             # Einmaliges Setup-Skript für Linux
└── README.md
```

> **Stalwart erzeugt beim ersten Start automatisch:**
> - `/opt/stalwart/etc/config.toml`
> - Admin-Account + Passwort (sichtbar in `docker logs stalwart`)
> - RocksDB Datenbank unter `/opt/stalwart/data/`

---

## Schritt-für-Schritt: Linux-Server einrichten

### 1. Docker installieren

```bash
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
# Ausloggen + Einloggen damit die Gruppe greift
```

### 2. Projekt vom GitHub holen

```bash
git clone https://github.com/DEIN-USER/smtprelay.git
cd smtprelay
```

### 3. Container starten

```bash
docker compose up -d
```

### 4. Admin-Passwort auslesen

```bash
docker logs stalwart
```

Ausgabe enthält:
```
✅ Configuration file written to /opt/stalwart/etc/config.toml
🔑 Your administrator account is 'admin' with password 'XXXXXXXX'.
```

### 5. Web-Interface öffnen

```
http://<SERVER-IP>:8080/login
```

Login: `admin` + Passwort aus Schritt 4.

### 6. Im Web-Interface konfigurieren

| Schritt | Wo | Was |
|---------|----|-----|
| **Hostname** | Settings → Server → Network | Server-FQDN eintragen (z.B. `mail.example.com`) |
| **Domain** | Management → Directory → Domains | Domain hinzufügen → DNS-Records werden angezeigt |
| **TLS** | Settings → Server → TLS → ACME Providers | Let's Encrypt aktivieren ODER eigenes Zertifikat hochladen |
| **Storage** | Settings → Storage | Standard = RocksDB (kann so bleiben) |
| **User** | Management → Directory → Accounts | SMTP-User anlegen |

### 7. DNS-Records setzen

Nach Anlegen der Domain im Web-Interface zeigt Stalwart die nötigen DNS-Records:
- **MX** Record → auf den Server
- **SPF** TXT Record
- **DKIM** TXT Records (werden automatisch generiert)
- **DMARC** TXT Record

### 8. Container neustarten

```bash
docker restart stalwart
```

---

## Docker-Befehle

```bash
# Starten
docker compose up -d

# Logs (live)
docker compose logs -f stalwart

# Status
docker compose ps

# Stoppen
docker compose down

# Neustarten
docker restart stalwart

# Update auf neuestes Image
docker compose pull && docker compose up -d

# In Container einsteigen
docker exec -it stalwart /bin/sh
```

---

## Port-Übersicht

| Port | Protokoll | Verwendung |
|------|-----------|------------|
| `25` | SMTP | Eingehend (MTA-to-MTA) |
| `587` | SMTP + STARTTLS | Client-Submission (mit Auth) |
| `465` | SMTPS | Client-Submission (TLS direkt) |
| `443` | HTTPS | Web-Interface (TLS) |
| `8080` | HTTP | Web-Interface (Setup) |

---

## Firewall (ufw)

```bash
sudo ufw allow 25/tcp
sudo ufw allow 587/tcp
sudo ufw allow 465/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
```

---

## Verbindung testen

```bash
# SMTP
telnet localhost 25

# SMTP mit Auth (swaks)
swaks --to test@example.com \
      --from relay@example.com \
      --server localhost:587 \
      --auth-user admin \
      --auth-password PASSWORT \
      --tls

# TLS prüfen
openssl s_client -starttls smtp -connect localhost:587
```

---

## GitHub Workflow (Dev → Server)

```bash
# Lokal (Windows)
git add . && git commit -m "update" && git push

# Auf dem Server
git pull origin main
docker compose down && docker compose up -d
```

---

## Daten / Volumes

Stalwart speichert alles im Docker Volume `stalwart-data` → `/opt/stalwart/`:
- `etc/config.toml` – Konfiguration (über Web-UI verwaltet)
- `data/` – Datenbank, Queue, Logs
- `logs/` – Server-Logs

Volume anzeigen:
```bash
docker volume inspect smtprelay_stalwart-data
```

---

## Links

- [Stalwart Doku – Docker Install](https://stalw.art/docs/install/platform/docker/)
- [Stalwart Doku – DNS Setup](https://stalw.art/docs/install/dns)
- [Stalwart Doku – Security](https://stalw.art/docs/install/security)
- [Stalwart GitHub](https://github.com/stalwartlabs/mail-server)
