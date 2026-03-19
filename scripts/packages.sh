#!/bin/bash

install_packages() {
  echo ""
  echo "📦 Instalando pacotes..."

  if [ "$DATABASE" == "sqlserver" ]; then
    run "dotnet add src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj package Microsoft.EntityFrameworkCore.SqlServer --version 8.0.0"
  elif [ "$DATABASE" == "postgres" ]; then
    run "dotnet add src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj package Npgsql.EntityFrameworkCore.PostgreSQL --version 8.0.0"
  fi

  run "dotnet add src/Infrastructure/$PROJECT_NAME.Infrastructure.csproj package Microsoft.EntityFrameworkCore --version 8.0.0"

  if [ "$CQRS" == "yes" ] || [ "$PIPELINE" == "yes" ]; then
    run "dotnet add src/Application/$PROJECT_NAME.Application.csproj package MediatR"
  fi

  if [ "$AUTH" == "jwt" ]; then
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package Microsoft.AspNetCore.Authentication.JwtBearer --version 8.0.0"
  fi


  if [ "$PIPELINE" == "yes" ]; then
    echo ""
    echo "📦 Instalando pacotes Pipeline Behaviors..."
    run "dotnet add src/Application/$PROJECT_NAME.Application.csproj package MediatR"
    run "dotnet add src/Application/$PROJECT_NAME.Application.csproj package FluentValidation"
    run "dotnet add src/Application/$PROJECT_NAME.Application.csproj package FluentValidation.DependencyInjectionExtensions"
    run "dotnet add src/Application/$PROJECT_NAME.Application.csproj package Microsoft.Extensions.Logging.Abstractions"


    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package Serilog.AspNetCore"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package Serilog.Sinks.Console"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Extensions.Hosting"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Exporter.Console"
  fi

  if [ "$OBSERVABILITY" == "yes" ]; then
    echo ""
    echo "📡 Instalando pacotes OpenTelemetry..."
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Extensions.Hosting"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Exporter.Prometheus.AspNetCore --prerelease"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Instrumentation.AspNetCore"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Instrumentation.Http"
    run "dotnet add src/WebApi/$PROJECT_NAME.WebApi.csproj package OpenTelemetry.Instrumentation.Runtime"
  fi
}
