#!/bin/bash

# ----------------------------------------------------------------------
# Log de Execução: Redireciona todas as saídas para /var/log/user-data.log
# ----------------------------------------------------------------------
exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Iniciando script de inicializacao (User Data) ==="

# ----------------------------------------------------------------------
# 1. Configuração do Fuso Horário (Timezone: America/Sao_Paulo)
# ----------------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configurando fuso horario para America/Sao_Paulo..."
timedatectl set-timezone America/Sao_Paulo
systemctl restart chronyd || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Fuso horario configurado com sucesso: $(date)"

# ----------------------------------------------------------------------
# 2. Atualização dos Pacotes do Sistema Operacional
# ----------------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Atualizando pacotes do sistema com DNF..."
dnf update -y

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Script de inicializacao concluido com sucesso! ==="
