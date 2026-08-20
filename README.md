# Documentação do Script de Instalação e Configuração

![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white)
![Bash](https://img.shields.io/badge/Shell_Script-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)


Esta documentação descreve o funcionamento do script `install_wireguard.sh`, agora com novas funcionalidades de validação, segurança e compatibilidade.

## Novas Funcionalidades e Melhorias

O script foi refatorado para garantir maior robustez e facilidade de uso. As principais mudanças incluem:

1.  **Validação de Entradas**: Verificação automática de formatos de IP (CIDR) e Endpoints (Host:Porta).
2.  **Segurança Aprimorada**:
    *   Uso de `umask 077` para garantir que chaves e configurações sejam criadas com permissões restritas (apenas root).
    *   Verificação de ID do Sistema Operacional (alerta em não-Debian).
3.  **Idempotência e Backups**:
    *   O script detecta se o arquivo de configuração `wg0.conf` já existe.
    *   Cria automaticamente um backup (`.bak.<timestamp>`) antes de sobrescrever.
    *   Não recria as chaves se elas já existirem, preservando a identidade do cliente.
4.  **Ativação Automática**: Prompt interativo ao final para ativar e habilitar o serviço `wg-quick` automaticamente.

---

## Guia de Uso

### 1. Execução
Execute o script como root:
```bash
sudo ./install_wireguard.sh
```

### 2. Fluxo Interativo
O script solicitará as informações necessárias de forma interativa. Veja o que esperar:

*   **Verificação de Sistema**: Se não estiver em Debian, pedirá confirmação para prosseguir.
*   **IP do Cliente**: Digite o IP interno VPN (ex: `10.0.0.2/32`). O script validará o formato.
*   **Chave Pública do Servidor**: Cole a chave pública fornecida pelo administrador do servidor VPN.
*   **Endpoint**: IP ou Domínio do servidor e porta (ex: `vpn.empresa.com:51820`). Se você esquecer a porta, o script adicionará `:51820` automaticamente.
*   **IPs Permitidos**: Redes que devem trafegar pela VPN (Default: `0.0.0.0/0` - Tudo).
*   **DNS**: Servidor DNS para usar no túnel (Default: `1.1.1.1`).

### 3. Finalização e Ativação
Ao final, o arquivo `/etc/wireguard/wg0.conf` será gerado.
O script perguntará:
> "Deseja iniciar e habilitar a conexão VPN agora? (s/n)"

*   **S (Sim)**: Habilita o serviço no boot e inicia imediatamente.
*   **N (Não)**: Apenas gera o arquivo. Você pode iniciar manualmente depois.

---

## Comandos Úteis

Se você optou por não ativar automaticamente, use os comandos abaixo:

*   **Iniciar VPN**: `sudo wg-quick up wg0`
*   **Parar VPN**: `sudo wg-quick down wg0`
*   **Verificar Status**: `sudo wg show`
*   **Habilitar no Boot**: `sudo systemctl enable wg-quick@wg0`

## Solução de Problemas

*   **Erro "IP inválido"**: O script exige notação CIDR (ex: `/32` ou `/24`) para IPs completos.
*   **Permissões**: O arquivo `wg0.conf` e as chaves são criados com permissão `600` (leitura/escrita apenas para root) por segurança. Se precisar ler manualmente, use `sudo cat`.
