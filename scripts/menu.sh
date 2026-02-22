#!/bin/bash
source "$BASE_DIR/scripts/utils.sh"

show_menu() {
  BOLD='\033[1;37m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color (Reset)

  echo -e "${BLUE}==================================================================================================================================${NC}"
  echo -e "${BOLD} 
            ████████╗███████╗███╗   ███╗██████╗ ██╗      █████╗ ████████╗███████╗███████╗     ██████╗██╗     ██╗
            ╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔════╝    ██╔════╝██║     ██║
               ██║   █████╗  ██╔████╔██║██████╔╝██║     ███████║   ██║   █████╗  ███████╗    ██║     ██║     ██║
               ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ╚════██║    ██║     ██║     ██║
               ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗██║  ██║   ██║   ███████╗███████║    ╚██████╗███████╗██║
               ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝     ╚═════╝╚══════╝╚═╝${NC}"
  echo -e "${BLUE}==================================================================================================================================${NC}"

  echo "Digite o nome do projeto:"
  read PROJECT_NAME

  if ! validate_project_name "$PROJECT_NAME"; then
    exit 1
  fi

  echo ""
  echo "Escolha o banco de dados:"
  echo "1 - SQL Server"
  echo "2 - PostgreSQL"
  read DB_OPTION

  case $DB_OPTION in
    1) DATABASE="sqlserver" ;;
    2) DATABASE="postgres" ;;
    *) echo "❌ Opção inválida"; exit 1 ;;
  esac

  echo ""
  echo "Deseja configurar autenticação JWT?"
  echo "1 - Sim"
  echo "2 - Não"
  read AUTH_OPTION

  case $AUTH_OPTION in
    1) AUTH="jwt" ;;
    2) AUTH="none" ;;
    *) echo "❌ Opção inválida"; exit 1 ;;
  esac

  echo ""
  echo "Deseja configurar Docker?"
  echo "1 - Sim"
  echo "2 - Não"
  read DOCKER_OPTION

  case $DOCKER_OPTION in
    1) DOCKER="yes" ;;
    2) DOCKER="no" ;;
    *) echo "❌ Opção inválida"; exit 1 ;;
  esac

  echo ""
  echo "Deseja configurar CQRS?"
  echo "1 - Sim"
  echo "2 - Não"
  read CQRS_OPTION

  case $CQRS_OPTION in
    1) CQRS="yes" ;;
    2) CQRS="no" ;;
    *) echo "❌ Opção inválida"; exit 1 ;;
  esac

  echo ""
  echo "Deseja ativar Observability? (Prometheus + Grafana + OpenTelemetry)"
  echo "1 - Sim"
  echo "2 - Não"
  read OBSERVABILITY_OPTION

  case $OBSERVABILITY_OPTION in
    1) OBSERVABILITY="yes" ;;
    2) OBSERVABILITY="no" ;;
    *) echo "❌ Opção inválida"; exit 1 ;;
  esac

  echo ""
  echo "Deseja configurar PIPELINE BEHAVIORS (Logs e Performance Behaviors)?"
  echo "1 - Sim"
  echo "2 - Não"
  read PIPELINE_OPTION

  case $PIPELINE_OPTION in
    1) PIPELINE="yes" ;;
    2) PIPELINE="no" ;;
    *) echo "❌ Opção inválida"; exit 1 ;;
  esac

  export PROJECT_NAME
  export DATABASE
  export AUTH
  export DOCKER
  export CQRS
  export OBSERVABILITY
  export PIPELINE
}
