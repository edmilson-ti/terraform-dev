## 🚀 Primeiro Passo: Inicialização do Laboratório

> ⚠️ **IMPORTANTE (Conta Temporária Pluralsight):** Devido às limitações de permissão e ao ciclo de vida da conta temporária do Pluralsight, o bucket S3 que armazenará o Terraform State **precisa ser criado manualmente antes de qualquer outra configuração**.

### Fluxo de Inicialização do State:

1. **Criação do Bucket S3**: Crie o bucket diretamente via AWS Console ou CLI utilizando a sua conta temporária.
2. **Configuração do Backend**: Após a criação física do bucket, insira as informações de nome e região dele dentro do bloco `backend "s3"` no arquivo `providers.tf`.
3. **Inicialização**: Execute o comando `terraform init` no seu terminal para migrar o estado local para a nuvem.
