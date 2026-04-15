#!/bin/bash
# ═══════════════════════════════════════════════════════
#  setup.sh – Erstkonfiguration für Stalwart SMTP Relay
#  Ausführen auf dem Linux-Server:
#    chmod +x scripts/setup.sh && sudo ./scripts/setup.sh
# ═══════════════════════════════════════════════════════
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Stalwart SMTP Relay – Setup ===${NC}"

# ─── 1. Docker installieren (Debian/Ubuntu) ───────────
install_docker() {
  if command -v docker &>/dev/null; then
    echo -e "${YELLOW}Docker ist bereits installiert: $(docker --version)${NC}"
    return
  fi

  echo -e "${GREEN}[1/5] Docker wird installiert...${NC}"
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release

  # Offizieller Docker GPG Key
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # Docker Repository hinzufügen
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  systemctl enable docker
  systemctl start docker
  echo -e "${GREEN}✔ Docker installiert: $(docker --version)${NC}"
}

# ─── 2. Docker Compose installieren ──────────────────
install_compose() {
  if docker compose version &>/dev/null; then
    echo -e "${YELLOW}Docker Compose (Plugin) bereits vorhanden.${NC}"
    return
  fi
  echo -e "${GREEN}[2/5] Docker Compose Plugin wird installiert...${NC}"
  apt-get install -y docker-compose-plugin
  echo -e "${GREEN}✔ Docker Compose: $(docker compose version)${NC}"
}

# ─── 3. Verzeichnisstruktur anlegen ──────────────────
create_dirs() {
  echo -e "${GREEN}[3/5] Verzeichnisstruktur wird angelegt...${NC}"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  mkdir -p "${SCRIPT_DIR}/data"
  mkdir -p "${SCRIPT_DIR}/data/queue"
  mkdir -p "${SCRIPT_DIR}/data/logs"
  mkdir -p "${SCRIPT_DIR}/config/tls"
  chmod 750 "${SCRIPT_DIR}/config"
  echo -e "${GREEN}✔ Verzeichnisse angelegt unter: ${SCRIPT_DIR}${NC}"
}

# ─── 4. .env aus .env.example anlegen ────────────────
setup_env() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [ -f "${SCRIPT_DIR}/.env" ]; then
    echo -e "${YELLOW}.env existiert bereits – wird nicht überschrieben.${NC}"
    return
  fi
  echo -e "${GREEN}[4/5] .env wird aus .env.example erzeugt...${NC}"
  cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
  echo -e "${RED}!!! Bitte .env anpassen: nano ${SCRIPT_DIR}/.env !!!${NC}"
}

# ─── 5. Firewall-Ports öffnen (ufw) ──────────────────
setup_firewall() {
  if ! command -v ufw &>/dev/null; then
    echo -e "${YELLOW}ufw nicht gefunden – Firewall übersprungen.${NC}"
    return
  fi
  echo -e "${GREEN}[5/5] Firewall-Ports werden geöffnet (ufw)...${NC}"
  ufw allow 25/tcp   comment "SMTP"
  ufw allow 587/tcp  comment "SMTP Submission"
  ufw allow 465/tcp  comment "SMTPS"
  ufw allow 8080/tcp comment "Stalwart Admin"
  echo -e "${GREEN}✔ UFW Regeln gesetzt.${NC}"
}

# ─── Ausführen ────────────────────────────────────────
install_docker
install_compose
create_dirs
setup_env
setup_firewall

echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup abgeschlossen!${NC}"
echo -e "${GREEN}  Nächste Schritte:${NC}"
echo -e "${YELLOW}  1. .env anpassen:  nano .env${NC}"
echo -e "${YELLOW}  2. Starten:        docker compose up -d${NC}"
echo -e "${YELLOW}  3. Logs:           docker compose logs -f stalwart${NC}"
echo -e "${YELLOW}  4. Admin:          http://<SERVER-IP>:8080${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
