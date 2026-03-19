#!/bin/bash

set -e

# ==============================
# Vini Clean Architecture CLI
# ==============================

# Obter o diretório atual do script principal
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carregar módulos
source "$BASE_DIR/scripts/utils.sh"
source "$BASE_DIR/scripts/menu.sh"
source "$BASE_DIR/scripts/structure.sh"
source "$BASE_DIR/scripts/packages.sh"
source "$BASE_DIR/scripts/generators.sh"

clear

# 1. Exibir menu e ler as configurações
show_menu

# 2. Criar estrutura do projeto
create_structure
add_to_solution
setup_references

# 3. Instalar pacotes
install_packages

# 4. Criar e configurar arquivos base e Docker
generate_dbcontext
generate_repository_base
generate_dockerfile
generate_unit_of_work
generate_cqrs
generate_exception_handler
generate_mediatr_di
generate_infrastructure_di
generate_program_cs_base
generate_observability
generate_pipeline_behaviors

# 5. Inicializar o Git e compilar
echo ""
echo "🔧 Inicializando git..."

run "git init"
run "dotnet build"

echo ""
echo "✅ Projeto criado com sucesso!"
echo ""
echo "Estrutura criada seguindo Clean Architecture."
echo ""