#!/bin/bash

# Script de instalação e configuração do WireGuard Client no Debian 13
# Autor: Antigravity (IA)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Iniciando a instalação do WireGuard Client no Debian 13...${NC}"

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script deve ser executado como root (sudo).${NC}"
   exit 1
fi

# 1. Atualizar o sistema e instalar dependências
echo "Atualizando repositórios e instalando pacotes..."
apt update
apt install -y wireguard wireguard-tools resolvconf

# 2. Gerar chaves se não existirem
DIR_WG="/etc/wireguard"
mkdir -p "$DIR_WG"
chmod 700 "$DIR_WG"

CLIENT_PRIVATE_KEY_FILE="$DIR_WG/client_private.key"
CLIENT_PUBLIC_KEY_FILE="$DIR_WG/client_public.key"

if [ ! -f "$CLIENT_PRIVATE_KEY_FILE" ]; then
    echo "Gerando chaves do cliente..."
    wg genkey | tee "$CLIENT_PRIVATE_KEY_FILE" | wg pubkey > "$CLIENT_PUBLIC_KEY_FILE"
    chmod 600 "$CLIENT_PRIVATE_KEY_FILE"
fi

CLIENT_PRIVATE_KEY=$(cat "$CLIENT_PRIVATE_KEY_FILE")
CLIENT_PUBLIC_KEY=$(cat "$CLIENT_PUBLIC_KEY_FILE")

echo -e "${GREEN}Chave Pública do Cliente:${NC} $CLIENT_PUBLIC_KEY"
echo "----------------------------------------------------------"
echo "Por favor, adicione esta chave pública no seu servidor VPN."
echo "----------------------------------------------------------"

# 3. Coletar informações do usuário
read -p "Digite o Endereço IP Virtual do Cliente (ex: 10.0.0.2/32): " CLIENT_IP
read -p "Digite a Chave Pública do Servidor: " SERVER_PUBKEY
read -p "Digite o Endpoint do Servidor (IP_OU_HOST:PORTA): " SERVER_ENDPOINT

# Validar se o endpoint possui porta. Se não, adicionar a padrão 51820.
if [[ "$SERVER_ENDPOINT" != *:* ]]; then
    echo -e "${RED}Aviso: Porta não detectada no endpoint. Usando padrão 51820.${NC}"
    SERVER_ENDPOINT="${SERVER_ENDPOINT}:51820"
fi

read -p "Digite os IPs Permitidos (Default: 0.0.0.0/0 para tudo): " ALLOWED_IPS
ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0}
read -p "Digite o DNS (Default: 1.1.1.1): " DNS_SERVER
DNS_SERVER=${DNS_SERVER:-1.1.1.1}

# 4. Criar o arquivo de configuração wg0.conf
WG_CONF="$DIR_WG/wg0.conf"

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

chmod 600 "$WG_CONF"

echo -e "${GREEN}Configuração concluída com sucesso em $WG_CONF${NC}"
echo ""
echo "Comandos úteis:"
echo "  Ativar VPN:  sudo wg-quick up wg0"
echo "  Desativar:   sudo wg-quick down wg0"
echo "  Status:      sudo wg"
echo "  Habilitar no boot: sudo systemctl enable wg-quick@wg0"
