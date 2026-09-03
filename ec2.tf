module "ec2_instance_app_dev" {
  source = "./modules/ec2-instance" # Aponta para a pasta do módulo
  
  instance_name     = "AWS-APP-DEV-01"
  ami_id   = "ami-0c101f26f147fa7fd"
  key_name_aws       = "kp-dev-edmilson" # Nome exato da chave na Console AWS, se estiver vazio o terraform se encarrega de gerar a chave
  instance_type     = "t3.small"
  os_disk_size_gb   = 30 # Define o tamanho disco de boot
  data_disk_size_gb = 0     # Define o tamanho do disco de dados para criar o disco insira um tamanho maior que 0
  
  assign_public_ip  = false  # Cria um elastic IP que será estático! Verifique se a quota do cliente vai permitir a criação deste IP
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.private_subnets[0]
  additional_security_group_ids = [] # Inclui security groups adicionais EXEMPLO: ["sg-0123abcdeEXAMPLE", "sg-fghij6789EXAMPLE"]

  private_key_save_path = "./keys" # Localização das chaves de acesso gerado pelo terraform
  install_cloudwatch_agent = false # Instala o agente do cloudwatch para metricas de memoria ram e disco
  user_data_script         = file("./scripts/userdata_linux.sh") # Caminho do script, userdata_windows.ps1 para windows e userdata_linux.sh para linux

  custom_tags = {
    "Ambiente"                   = "Desenvolvimento"
    "ManagedBy" = "Terraform"
  }
}