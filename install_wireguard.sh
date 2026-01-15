#!/bin/bash

# Script de instalação e configuração do WireGuard Client no Debian 13
# Autor: Antigravity (IA)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Funções de Validação
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
       echo -e "${RED}Este script deve ser executado como root (sudo).${NC}"
       exit 1
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
            echo -e "${YELLOW}Aviso: Este script foi testado em Debian. Seu sistema parece ser: $PRETTY_NAME.${NC}"
            read -p "Deseja continuar mesmo assim? (s/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Ss]$ ]]; then
                exit 1
            fi
        fi
    else
        echo -e "${RED}Erro: Não foi possível detectar o sistema operacional.${NC}"
        exit 1
    fi
}

# --- Início do Script ---

echo -e "${GREEN}Iniciando a instalação do WireGuard Client...${NC}"

check_root
check_os

# 1. Atualizar o sistema e instalar dependências
echo "Atualizando repositórios e instalando pacotes..."
apt update
apt install -y wireguard wireguard-tools resolvconf

# 2. Configuração de Segurança e Diretórios
DIR_WG="/etc/wireguard"
mkdir -p "$DIR_WG"
chmod 700 "$DIR_WG"

# Umask para garantir que arquivos criados sejam restritos (600/700)
umask 077

CLIENT_PRIVATE_KEY_FILE="$DIR_WG/client_private.key"
CLIENT_PUBLIC_KEY_FILE="$DIR_WG/client_public.key"

if [ ! -f "$CLIENT_PRIVATE_KEY_FILE" ]; then
    echo "Gerando chaves do cliente..."
    wg genkey | tee "$CLIENT_PRIVATE_KEY_FILE" | wg pubkey > "$CLIENT_PUBLIC_KEY_FILE"
else
    echo -e "${YELLOW}Chaves já existentes. Pulando geração.${NC}"
fi

CLIENT_PRIVATE_KEY=$(cat "$CLIENT_PRIVATE_KEY_FILE")
CLIENT_PUBLIC_KEY=$(cat "$CLIENT_PUBLIC_KEY_FILE")

echo -e "${GREEN}Chave Pública do Cliente:${NC} $CLIENT_PUBLIC_KEY"
echo "----------------------------------------------------------"
echo "Por favor, adicione esta chave pública no seu servidor VPN."
echo "----------------------------------------------------------"

# 3. Coletar informações do usuário com validação
while true; do
    read -p "Digite o Endereço IP Virtual do Cliente (ex: 10.0.0.2/32): " CLIENT_IP
    if validate_ip "$CLIENT_IP"; then
        break
    else
        echo -e "${RED}IP inválido. Tente novamente.${NC}"
    fi
done

read -p "Digite a Chave Pública do Servidor: " SERVER_PUBKEY

while true; do
    read -p "Digite o Endpoint do Servidor (IP_OU_HOST:PORTA): " SERVER_ENDPOINT
    # Validar se o endpoint possui porta. Se não, adicionar a padrão 51820.
    if [[ "$SERVER_ENDPOINT" != *:* ]]; then
        echo -e "${YELLOW}Aviso: Porta não detectada no endpoint. Usando padrão 51820.${NC}"
        SERVER_ENDPOINT="${SERVER_ENDPOINT}:51820"
    fi
    # Verificação básica se não está vazio
    if [[ -n "$SERVER_ENDPOINT" ]]; then
        break
    fi
done

read -p "Digite os IPs Permitidos (Default: 0.0.0.0/0 para tudo): " ALLOWED_IPS
ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0}

read -p "Digite o DNS (Default: 1.1.1.1): " DNS_SERVER
DNS_SERVER=${DNS_SERVER:-1.1.1.1}

# 4. Criar o arquivo de configuração wg0.conf com backup
WG_CONF="$DIR_WG/wg0.conf"

if [ -f "$WG_CONF" ]; then
    BACKUP_NAME="$WG_CONF.bak.$(date +%s)"
    echo -e "${YELLOW}Arquivo de configuração já existe. Criando backup em $BACKUP_NAME${NC}"
    cp "$WG_CONF" "$BACKUP_NAME"
fi

cat <<EOF > "$WG_CONF"
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = $DNS_SERVER

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# Permissão explícita, embora umask já deva ter tratado
chmod 600 "$WG_CONF"

echo -e "${GREEN}Configuração concluída com sucesso em $WG_CONF${NC}"
echo ""

# 5. Ativação do Serviço
echo "Deseja iniciar e habilitar a conexão VPN agora?"
read -p "(s/n): " -n 1 -r REPLY_SERVICE
echo
if [[ $REPLY_SERVICE =~ ^[Ss]$ ]]; then
    echo "Iniciando wg-quick@wg0..."
    if systemctl enable --now wg-quick@wg0; then
         echo -e "${GREEN}VPN Ativada com sucesso!${NC}"
         echo "Status atual:"
         wg show
    else
         echo -e "${RED}Falha ao iniciar a VPN.${NC}"
    fi
else
    echo "Ok. Comandos úteis para depois:"
    echo "  Ativar VPN:  sudo wg-quick up wg0"
    echo "  Desativar:   sudo wg-quick down wg0"
    echo "  Status:      sudo wg"
    echo "  Habilitar:   sudo systemctl enable wg-quick@wg0"
fi
