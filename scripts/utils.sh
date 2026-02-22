#!/bin/bash

# ------------------------------
# Helpers
# ------------------------------

run() {
  echo "▶ $1"
  eval $1
}

pause() {
  read -p "Pressione Enter para continuar..."
}

validate_project_name() {
  local name="$1"

  # Não pode ser vazio
  if [[ -z "$name" ]]; then
    echo "❌ Nome não pode ser vazio."
    return 1
  fi

  # Deve começar com letra ou número
  if [[ ! "$name" =~ ^[A-Za-z0-9] ]]; then
    echo "❌ Deve começar com letra ou número."
    return 1
  fi

  # Apenas caracteres permitidos
  if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "❌ Caracteres inválidos."
    echo "Permitidos: letras, números, '.', '-' e '_'."
    return 1
  fi

  # Não pode conter ".."
  if [[ "$name" == *".."* ]]; then
    echo "❌ Não pode conter '..'."
    return 1
  fi

  # Não pode terminar com '.' ou '-'
  if [[ "$name" =~ [.-]$ ]]; then
    echo "❌ Não pode terminar com '.' ou '-'."
    return 1
  fi

  # Evitar nomes problemáticos no Windows
  case "${name,,}" in
    con|prn|aux|nul|com1|com2|com3|com4|com5|com6|com7|com8|com9|lpt1|lpt2|lpt3|lpt4|lpt5|lpt6|lpt7|lpt8|lpt9)
      echo "❌ Nome reservado no Windows."
      return 1
      ;;
  esac

  return 0
}
