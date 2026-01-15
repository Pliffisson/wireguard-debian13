# Documentação das Configurações do WireGuard

Esta documentação explica detalhadamente cada parâmetro utilizado no arquivo de configuração do WireGuard (`wg0.conf`) gerado pelo script.

## Estrutura do Arquivo de Configuração

O WireGuard utiliza um formato de configuração simples dividido em seções: `[Interface]` (configurações locais) e `[Peer]` (configurações do servidor remoto).

---

### Seção [Interface]
Esta seção define as configurações da interface de rede VPN no seu dispositivo local (o cliente).

- **`PrivateKey`**: A chave privada do cliente. Nunca compartilhe esta chave. Ela é usada para descriptografar o tráfego que chega até você.
- **`Address`**: Define o endereço IP virtual do cliente dentro da rede VPN (ex: `10.0.0.2/32`). O `/32` indica que este é um endereço único para este dispositivo.
- **`DNS`**: Define os servidores DNS que o cliente usará enquanto a VPN estiver ativa. Isso ajuda a prevenir "DNS leaks" (vazamentos de DNS) e permite resolver nomes através do túnel.

---

### Seção [Peer]
Esta seção define as configurações do servidor VPN (ou outro dispositivo) ao qual você está se conectando.

- **`PublicKey`**: A chave pública do **servidor**. Ela é usada para criptografar o tráfego enviado para o servidor.
- **`Endpoint`**: O endereço IP público ou domínio e a porta do servidor VPN (ex: `vpn.exemplo.com:51820`). É para onde o cliente enviará os pacotes criptografados.
- **`AllowedIPs`**: Define quais endereços IP serão roteados através da VPN.
    - `0.0.0.0/0`: Roteia **todo** o tráfego da internet pela VPN (Full Tunnel).
    - `10.0.0.0/24`: Roteia apenas o tráfego destinado à rede interna da VPN (Split Tunnel).
- **`PersistentKeepalive`**: Envia um pacote de "manutenção" a cada X segundos (geralmente 25). É essencial para manter a conexão ativa se o cliente estiver atrás de um NAT ou Firewall rígido.

---

## Guia Passo a Passo de Configuração

### 1. Preparação no Cliente (Debian 13)
Execute o script de instalação para preparar o ambiente e gerar as chaves:
```bash
sudo bash install_wireguard.sh
```
O script irá:
1. Instalar os pacotes necessários.
2. Gerar sua **Chave Pública** (exibida ao final).
3. Criar o arquivo de configuração `/etc/wireguard/wg0.conf`.

### 2. Configuração no Servidor (Ação Requerida)
Para que a conexão funcione, o **servidor** precisa conhecer o seu cliente. Você (ou o admin do servidor) deve adicionar o seu cliente à configuração do servidor (geralmente em `/etc/wireguard/wg0.conf` do servidor):

```ini
# Exemplo de como o seu cliente aparece no SERVIDOR
[Peer]
PublicKey = <SUA_CHAVE_PUBLICA_GERADA_PELO_SCRIPT>
AllowedIPs = <SEU_IP_VPN_EX_10.0.0.2/32>
```
Após editar, o servidor deve ser reiniciado ou atualizado (`sudo wg syncconf wg0 <(wg-quick strip wg0)`).

### 3. Estabelecendo a Conexão
No seu Debian 13, inicie o túnel:
```bash
sudo wg-quick up wg0
```

### 4. Verificação
Verifique se a conexão está ativa e se há troca de dados (Handshake):
```bash
sudo wg show
```
Se você vir "latest handshake: 1 second ago", a conexão foi estabelecida com sucesso!

## Solução de Problemas (Troubleshooting)

- **Sem Handshake**: Verifique se o `Endpoint` (IP e Porta) do servidor está correto e se a porta (geralmente 51820 UDP) está aberta no firewall do servidor.
- **Sem Internet**: Se estiver usando `AllowedIPs = 0.0.0.0/0`, certifique-se de que o servidor VPN está configurado para fazer NAT/Masquerade do tráfego.
- **DNS não funciona**: Verifique o campo `DNS` no seu `wg0.conf`. Tente usar `8.8.8.8` ou o IP do servidor VPN se ele prover DNS.

---

## Conceitos de Segurança

### Par de Chaves (Asymmetric Cryptography)
O WireGuard utiliza criptografia assimétrica baseada em Curve25519:
1.  **Chave Privada**: Fica apenas no dispositivo.
2.  **Chave Pública**: Derivada da privada, é compartilhada com o outro lado da conexão (o "Peer").

**Regra de Ouro**: O Servidor precisa conhecer a Chave Pública do Cliente, e o Cliente precisa conhecer a Chave Pública do Servidor.

## Gerenciamento da Conexão

- **`wg-quick up wg0`**: Lê a configuração em `/etc/wireguard/wg0.conf`, cria a interface de rede, define as rotas e configura o DNS.
- **`wg-quick down wg0`**: Remove a interface de rede e restaura as rotas e configurações de DNS originais do sistema.
