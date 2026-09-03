#!/bin/bash
set -euo pipefail

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

# Reinicia e sincroniza o servico de NTP (chrony)
if systemctl is-active --quiet chronyd; then
  systemctl restart chronyd
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Fuso horario atual: $(timedatectl | grep 'Time zone')"

# ----------------------------------------------------------------------
# 2. Atualização dos Pacotes do Sistema Operacional
# ----------------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Atualizando pacotes do sistema com DNF..."
dnf update -y

# Instala pacotes utilitarios essenciais
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Instalando pacotes utilitarios essenciais..."
dnf install -y curl wget vim htop git unzip

# ----------------------------------------------------------------------
# 3. Criação do Usuário Genérico de Administração
# ----------------------------------------------------------------------
NEW_USER="devops"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Verificando criacao do usuario generico '${NEW_USER}'..."
if ! id "${NEW_USER}" &>/dev/null; then
  # Cria o usuario com home directory e shell Bash
  useradd -m -s /bin/bash -c "Generic DevOps Admin User" "${NEW_USER}"
  
  # Adiciona ao grupo wheel (administradores sudo)
  usermod -aG wheel "${NEW_USER}"

  # Permissao sudo sem necessidade de senha
  echo "${NEW_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99-${NEW_USER}"
  chmod 0440 "/etc/sudoers.d/99-${NEW_USER}"

  # Copia a chave SSH publica da instancia (ec2-user) para o novo usuario
  # permitindo login imediato com a mesma chave SSH usada no provisionamento
  if [ -d "/home/ec2-user/.ssh" ] && [ -f "/home/ec2-user/.ssh/authorized_keys" ]; then
    mkdir -p "/home/${NEW_USER}/.ssh"
    cp "/home/ec2-user/.ssh/authorized_keys" "/home/${NEW_USER}/.ssh/authorized_keys"
    chown -R "${NEW_USER}:${NEW_USER}" "/home/${NEW_USER}/.ssh"
    chmod 700 "/home/${NEW_USER}/.ssh"
    chmod 600 "/home/${NEW_USER}/.ssh/authorized_keys"
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Usuario '${NEW_USER}' criado e configurado com sucesso!"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] O usuario '${NEW_USER}' ja existe no sistema."
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Script de inicializacao concluido com sucesso! ==="
