# 📑 Runbook: Esteira de CI/CD para Terraform com GitHub Actions

Este documento descreve o fluxo ponta a ponta para configurar, proteger e automatizar a implantação de infraestrutura como código (IaC) utilizando Terraform, GitHub e AWS (incluindo suporte a contas laboratoriais/temporárias).

---

## 🎯 Visão Geral da Arquitetura do Fluxo

```text
[Branch: develop] -> [Pull Request] -> [Pipeline de CI] -> [Aprovação/Merge] -> [Branch: main] -> [Pipeline de CD] -> [AWS]
```

1. **Proteção da Branch `main`**: Impede envios diretos à branch de produção.
2. **Desenvolvimento Isolado**: Alterações feitas estritamente na branch `develop`.
3. **Pipeline de CI (`terraform-ci.yml`)**: Valida a sintaxe do código a cada Pull Request.
4. **Pipeline de CD (`terraform-cd.yml`)**: Aplica as mudanças (`apply -auto-approve`) na AWS de forma 100% automatizada após o Merge.
5. **Persistência de Estado (Backend)**: Armazenamento permanente do arquivo `terraform.tfstate` no S3.

---

## 🛠️ Passo 1: Configuração do Ambiente Local e Segurança Inicial

Ao iniciar o repositório no seu computador local, garanta que os arquivos de suporte básicos estejam criados para evitar o vazamento de segredos para a nuvem.

### 1. Criar o arquivo `.gitignore`
Na raiz do projeto, crie o arquivo `.gitignore` para bloquear arquivos temporários e confidenciais do Terraform:

```gitignore
# Diretório local de cache e providers do Terraform
.terraform/

# Arquivos locais de estado (NUNCA enviar para o GitHub)
*.tfstate
*.tfstate.*.backup
*.tfstate.lock.info

# Arquivos de variáveis locais (contêm credenciais/senhas)
*.tfvars
*.tfvars.json

# Logs de falhas
crash.log
crash.*.log
```

### 2. Configurar a Identidade do Git no VS Code
Se o Git bloquear o seu primeiro commit por falta de identificação, execute no terminal integrado:
```bash
git config --global user.name "Seu Nome Completo"
git config --global user.email "seu_email_do_github@exemplo.com"
```

---

## 🔒 Passo 2: Proteção da Branch no GitHub

Para forçar o uso de revisões e pipelines, ative as regras de proteção na interface do GitHub:

1. Acesse o repositório no navegador e vá em **Settings** > **Rulesets** (ou *Branches* se usar o modelo clássico).
2. Crie um novo conjunto de regras (*New ruleset*) direcionado à branch `main`.
3. Ative as opções básicas de integridade:
   * **Block force pushes** (Impede que o histórico seja sobrescrito).
   * **Restrict deletions** (Impede que a branch principal seja deletada).
4. *Nota para Projetos Solo*: Se ativar `Require a pull request before merging`, certifique-se de que a opção de exigir aprovações de terceiros esteja desmarcada ou definida como `0`, permitindo que você mesmo execute o merge após o sucesso do CI.

---

## 📂 Passo 3: Criação das Pipelines no GitHub Actions

As pipelines devem ser estruturadas dentro do diretório específico `.github/workflows/` a partir da sua branch de desenvolvimento (`develop`).

### 1. Pipeline de CI (`.github/workflows/terraform-ci.yml`)
Esta esteira valida o código em cada abertura de Pull Request direcionado à branch principal.

```yaml
name: 'Terraform CI'

on:
  pull_request:
    branches:
      - main

jobs:
  terraform-ci:
    name: 'Terraform Validation'
    runs-on: ubuntu-latest

    env:
      AWS_ACCESS_KEY_ID: \${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: 'us-east-1'

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Init
      run: terraform init

    - name: Terraform Validate
      run: terraform validate
```

### 2. Pipeline de CD (`.github/workflows/terraform-cd.yml`)
Esta esteira aplica as mudanças na nuvem automaticamente de forma assíncrona assim que o código recebe o Merge.

```yaml
name: 'Terraform CD'

on:
  push:
    branches:
      - main

jobs:
  terraform-cd:
    name: 'Terraform Deployment'
    runs-on: ubuntu-latest

    env:
      AWS_ACCESS_KEY_ID: \${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: 'us-east-1'

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Init
      run: terraform init

    - name: Terraform Apply
      run: terraform apply -auto-approve
```

---

## 🔑 Passo 4: Configuração de Segredos (Secrets) no GitHub

Para que as pipelines acessem a nuvem de forma legítima, armazene as credenciais fora do código:

1. No repositório, vá em **Settings** > **Secrets and variables** > **Actions**.
2. Clique em **New repository secret** e adicione as variáveis:
   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`

---

## 🚀 Passo 5: Estrutura Base do Terraform (`providers.tf`)

O arquivo de provedor deve contemplar a declaração do backend remoto. Para mitigar o problema do *"ovo e da galinha"* (o backend precisar de um S3 que ainda não foi criado), utilize a estratégia comentada no primeiro deploy.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # =========================================================================
  # BACKEND REMOTO (S3)
  # Mantenha este bloco COMENTADO no primeiro commit. 
  # Descomente-o apenas APÓS o bucket ter sido criado fisicamente na nuvem.
  # =========================================================================
  # backend "s3" {
  #   bucket         = "edmilsonlima-cloud-terraform-dev-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "us-east-1"
}
```

---

## 🔄 Passo 6: A Rotina Diária de Execução (O Ciclo Sagrado)

Siga rigorosamente estes passos sempre que for trabalhar no projeto:

### 1. Atualizar e sincronizar o ambiente local
Nunca inicie um código novo sem trazer o que está em produção. Na interface do VS Code ou no terminal, execute:
```bash
git checkout main
git pull origin main
```

### 2. Criar uma ramificação para a nova tarefa
```bash
git checkout -b develop
```

### 3. Criar os recursos locais e testar
Escreva os códigos do Terraform (ex: `s3_bucket.tf`). Se for o primeiro deploy do projeto, execute localmente para dar origem física ao bucket de state:
```bash
terraform init
terraform apply -auto-approve
```

### 4. Ativar o Backend (Caso seja a criação do State)
Vá no `providers.tf`, retire os comentários (`#`) do bloco `backend "s3"` e execute:
```bash
terraform init
```
*Responda `yes` quando o terminal perguntar se deseja migrar o state local para o S3 remoto.*

### 5. Enviar as alterações usando os Conventional Commits
Use os prefixos corretos para manter o histórico limpo:
* `feat:` para novos recursos de infraestrutura.
* `fix:` para correções de bugs.
* `ci:` para alterações de workflows/pipelines.
* `chore:` para documentação, `.gitignore` ou configurações gerais.

```bash
git add .
git commit -m "ci: ativa o backend remoto s3 e adiciona esteiras"
git push origin develop
```

### 6. Concluir o ciclo no GitHub
1. Vá na aba **Pull Requests** do repositório.
2. Abra o PR de `develop` para `main`.
3. Aguarde o **check verde (✅)** da validação do `Terraform CI`.
4. Clique em **Merge pull request** e confirme.
5. Monitore a aba **Actions** para garantir que o `Terraform CD` execute o deploy final com sucesso.
