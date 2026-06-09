# Proxmox Terraform Book

Guia prático para operar este projeto Terraform no Proxmox.

## 1) Objetivo

Este repositório cria VMs no Proxmox usando módulos Terraform reutilizáveis.

Estrutura principal:
- infrastructure/modules/network
- infrastructure/modules/storage
- infrastructure/modules/vm
- infrastructure/environments/cluster01
- infrastructure/environments/cluster02

Cada ambiente define suas próprias variáveis em terraform.tfvars, principalmente o bloco vms.

## 2) Pré-requisitos

- Terraform instalado na máquina local
- Acesso ao Proxmox API
- Token válido do Proxmox (ID e Secret)
- Template cloud-init disponível no Proxmox (exemplo: ubuntu-24-04-cloudinit)
- Chave SSH pública para injetar nas VMs

## 2.1) Como criar token no Proxmox

Este projeto usa autenticação por API Token no provider Telmate/proxmox.

### Passo a passo no Proxmox UI

1. Criar usuário de automação (opcional, recomendado):
- Datacenter -> Permissions -> Users -> Add
- Exemplo de usuário: terraform@pve

2. Criar role para Terraform (recomendado):
- Datacenter -> Permissions -> Roles -> Create
- Exemplo: TerraformRole
- Privilégios comuns (ajuste ao seu cenário):
  - Datastore.AllocateSpace
  - VM.Allocate
  - VM.Clone
  - VM.Config.CDROM
  - VM.Config.CPU
  - VM.Config.Disk
  - VM.Config.Memory
  - VM.Config.Network
  - VM.Config.Options
  - VM.Monitor
  - VM.PowerMgmt
  - SDN.Use (se usar SDN)

3. Associar permissão no escopo correto:
- Datacenter -> Permissions -> Add
- Path: / (ou um nó/pool específico)
- User: terraform@pve
- Role: TerraformRole
- Marque Propagate se quiser herdar para subníveis

4. Criar API Token:
- Datacenter -> Permissions -> API Tokens -> Add
- User: terraform@pve
- Token ID: terraform
- Privilege Separation:
  - Desmarcado: token herda permissões do usuário
  - Marcado: você precisa atribuir permissões diretamente ao token
- Salve o Secret exibido (aparece uma vez)

### Formato para Terraform

No terraform.tfvars:
- pm_api_token_id = "terraform@pve!terraform"
- pm_api_token_secret = "SEU_SECRET_AQUI"

O formato de pm_api_token_id é:
- usuario@realm!tokenid

### Teste rápido de API (opcional)

Exemplo com curl:

curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform=SEU_SECRET_AQUI" \
  https://SEU_PROXMOX:8006/api2/json/version

Se retornar versão do Proxmox em JSON, o token está funcional.

### Boas práticas de segurança

- Evite commitar secrets reais no git
- Prefira exportar segredo via variável de ambiente:
  - export TF_VAR_pm_api_token_secret="SEU_SECRET_AQUI"
- Dê apenas permissões mínimas necessárias para o Terraform

## 3) Como usar Terraform neste projeto

### 3.1 Escolher ambiente

Exemplos:
- cluster01: infrastructure/environments/cluster01
- cluster02: infrastructure/environments/cluster02

### 3.2 Ajustar variáveis

Edite o terraform.tfvars do ambiente escolhido:
- pm_api_url
- pm_api_token_id
- pm_api_token_secret
- target_node
- clone_template
- storage_name
- bridge
- vlan_tag
- ssh_public_key
- vms

### 3.3 Executar ciclo Terraform

Rodar no diretório do ambiente.

Comandos:
- cd /mnt/c/workspace/infra/proxmox/infrastructure/environments/cluster01
- terraform init
- terraform plan
- terraform apply

Para destruir:
- terraform destroy

## 4) Diferença entre cluster01 e cluster02

### cluster01

Arquivo: infrastructure/environments/cluster01/terraform.tfvars

Perfil atual:
- Ambiente genérico de VMs
- 3 VMs no bloco vms (vm01, vm02, vm03)
- Recursos moderados
- Mistura de DHCP e IP fixo opcional

Uso recomendado:
- Laboratório geral
- Testes rápidos de automação

### cluster02

Arquivo: infrastructure/environments/cluster02/terraform.tfvars

Perfil atual OpenShift:
- bootstrap: 1 VM
- control-plane: 3 VMs (master01, master02, master03)
- workers: 2 VMs (worker01, worker02)
- Recursos maiores por nó
- IP fixo em todos os nós

Uso recomendado:
- Base de infraestrutura para instalação OpenShift

## 5) Como criar ambiente4

A forma mais simples é clonar um ambiente existente e ajustar terraform.tfvars.

Passo a passo:
1. Escolha base:
- Se quiser ambiente genérico: copie cluster01
- Se quiser perfil OpenShift: copie cluster02

2. Copie a pasta:
- cd /mnt/c/workspace/infra/proxmox/infrastructure/environments
- cp -r cluster01 ambiente4

3. Ajuste arquivos do novo ambiente:
- ambiente4/terraform.tfvars
- ambiente4/main.tf (opcional: descrição de outputs)

4. No terraform.tfvars, revise:
- Token e URL do Proxmox
- target_node
- clone_template
- storage_name, bridge e vlan_tag
- bloco vms inteiro

5. Valide e aplique:
- cd /mnt/c/workspace/infra/proxmox/infrastructure/environments/ambiente4
- terraform init
- terraform plan
- terraform apply

## 6) Como escalar quantidade de VMs

A quantidade de VMs é definida pelo número de itens no mapa vms.

Exemplo lógico:
- 2 entradas no vms = 2 VMs
- 6 entradas no vms = 6 VMs

Não é necessário alterar módulos para escalar. Basta adicionar ou remover entradas no vms.

## 7) Boas práticas

- Não versionar segredo real no terraform.tfvars
- Preferir usar variáveis de ambiente para segredo:
  - export TF_VAR_pm_api_token_secret="..."
- Usar nomes de VM padronizados por ambiente
- Reservar IPs fixos quando for cluster OpenShift
- Executar terraform plan antes de todo apply

## 8) Troubleshooting rápido

- Erro de autenticação:
  - Validar pm_api_token_id e pm_api_token_secret
- Erro de template:
  - Confirmar clone_template existente no node
- Erro de rede:
  - Validar bridge e vlan_tag
- Terraform não encontrado:
  - Instalar Terraform e repetir init/plan/apply
