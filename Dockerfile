# ──────────────────────────────────────────────────────
# Dockerfile – Stalwart SMTP Relay
# Basis: offizielles Stalwart Image
# ──────────────────────────────────────────────────────
FROM stalwartlabs/mail-server:latest

# Metadaten
LABEL maintainer="dein-name@example.com"
LABEL description="Stalwart SMTP Relay Server"

# Arbeitsverzeichnis
WORKDIR /opt/stalwart-mail

# Konfiguration ins Image kopieren
# (Alternative: per Volume in docker-compose.yml mounten – bevorzugt!)
COPY ./config/config.toml /opt/stalwart-mail/etc/config.toml

# Datenpfade anlegen
RUN mkdir -p \
    /opt/stalwart-mail/data \
    /opt/stalwart-mail/etc/tls \
    /opt/stalwart-mail/queue \
    /opt/stalwart-mail/logs \
    && chown -R stalwart:stalwart /opt/stalwart-mail || true

# Ports freigeben
EXPOSE 25 587 465 8080

# Startbefehl
CMD ["stalwart-mail", "--config", "/opt/stalwart-mail/etc/config.toml"]
