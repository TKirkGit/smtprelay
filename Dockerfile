# ──────────────────────────────────────────────────────
# Dockerfile – Stalwart SMTP Relay
# Basis: offizielles Stalwart Image
# Hinweis: Nur nötig wenn eigene Anpassungen ins Image sollen.
#          Für den Normalfall reicht docker-compose.yml allein.
# ──────────────────────────────────────────────────────
FROM stalwartlabs/stalwart:latest

# Metadaten
LABEL maintainer="dein-name@example.com"
LABEL description="Stalwart SMTP Relay Server"

# Arbeitsverzeichnis (offizieller Pfad laut Stalwart Doku)
WORKDIR /opt/stalwart

# Datenpfade anlegen
RUN mkdir -p /opt/stalwart/etc /opt/stalwart/data /opt/stalwart/logs

# Ports freigeben
EXPOSE 443 8080 25 587 465
