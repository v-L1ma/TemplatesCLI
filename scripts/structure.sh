#!/bin/bash

create_structure() {
  echo ""
  echo "🚀 Criando solução..."

  mkdir "$PROJECT_NAME"
  cd "$PROJECT_NAME"

  run "dotnet new sln -n $PROJECT_NAME"

  mkdir src
  mkdir tests

  cd src

  run "dotnet new webapi -n $PROJECT_NAME.WebApi -o WebApi"
  run "dotnet new classlib -n $PROJECT_NAME.Application -o Application"
  run "dotnet new classlib -n $PROJECT_NAME.Domain -o Domain"
  run "dotnet new classlib -n $PROJECT_NAME.Infrastructure -o Infrastructure"

  cd ../tests
  run "dotnet new xunit -n $PROJECT_NAME.Tests"

  cd ..
}

add_to_solution() {
  run "dotnet sln add src/WebApi/$PROJECT_NAME.WebApi.csproj"
  run "dotnet sln add src/Application/$PROJECT_NAME.Application.csproj"
  run "dotnet sln add src/Domain/$PROJECT_NAME.Domain.csproj"
  run "dotnet sln add src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj"
  run "dotnet sln add tests/$PROJECT_NAME.Tests/$PROJECT_NAME.Tests.csproj"
}

setup_references() {
  echo ""
  echo "🔗 Configurando referências..."

  run "dotnet add src/Application/$PROJECT_NAME.Application.csproj reference src/Domain/$PROJECT_NAME.Domain.csproj"

  run "dotnet add src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj reference src/Application/$PROJECT_NAME.Application.csproj"
  run "dotnet add src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj reference src/Domain/$PROJECT_NAME.Domain.csproj"

  run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj reference src/Application/$PROJECT_NAME.Application.csproj"
  run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj reference src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj"
}
