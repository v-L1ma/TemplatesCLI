#!/bin/bash

generate_dbcontext() {
  echo ""
  echo "📝 Criando AppDbContext..."

  # Criar pasta Models no Domain com classe placeholder
  mkdir -p src/Domain/Models

  cat <<EOF > src/Domain/Models/.gitkeep
EOF

  cat <<EOF > src/Infrastructure/AppDbContext.cs
using Microsoft.EntityFrameworkCore;

namespace $PROJECT_NAME.Infrastructure
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        // DbSets
        // TODO: Adicionar seus DbSets aqui
        // public DbSet<YourEntity> YourEntities { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // TODO: Configurar suas entidades aqui
        }
    }
}
EOF
}

generate_repository_base() {
  echo ""
  echo "📝 Criando IRepositoryBase..."

  mkdir -p src/Application/Repositories

  cat <<EOF > src/Application/Repositories/IRepositoryBase.cs
namespace $PROJECT_NAME.Application.Repositories
{
    public interface IRepositoryBase<T> where T : class
    {
        Task<T> GetByIdAsync(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task<bool> ExistsAsync(int id);
        Task AddAsync(T entity);
        Task UpdateAsync(T entity);
        Task DeleteAsync(T entity);
        Task SaveChangesAsync();
    }
}
EOF
}

generate_dockerfile() {
  if [ "$DOCKER" == "yes" ]; then
    echo "🐳 Criando Dockerfile..."

    cat <<EOF > src/WebApi/Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "$PROJECT_NAME.WebApi.dll"]
EOF
  fi
}

generate_cqrs() {
  if [ "$CQRS" == "yes" ]; then
    echo "🏗️ Criando estrutura CQRS..."

    mkdir -p src/Application/Abstractions/Messaging
    mkdir -p src/Application/Features/SampleFeature

    # ICommand.cs
    cat <<EOF > src/Application/Abstractions/Messaging/ICommand.cs
using MediatR;
using $PROJECT_NAME.Domain.Abstractions;

namespace $PROJECT_NAME.Application.Abstractions.Messaging
{
    public interface ICommand : IRequest<Result>
    {
    }

    public interface ICommand<TResponse> : IRequest<Result<TResponse>>
    {
    }
}
EOF

    # IQuery.cs
    cat <<EOF > src/Application/Abstractions/Messaging/IQuery.cs
using MediatR;
using $PROJECT_NAME.Domain.Abstractions;

namespace $PROJECT_NAME.Application.Abstractions.Messaging
{
    public interface IQuery<TResponse> : IRequest<Result<TResponse>>
    {
    }
}
EOF

    # ICommandHandler.cs
    cat <<EOF > src/Application/Abstractions/Messaging/ICommandHandler.cs
using MediatR;
using $PROJECT_NAME.Domain.Abstractions;

namespace $PROJECT_NAME.Application.Abstractions.Messaging
{
    public interface ICommandHandler<TCommand> : IRequestHandler<TCommand, Result>
        where TCommand : ICommand
    {
    }

    public interface ICommandHandler<TCommand, TResponse> : IRequestHandler<TCommand, Result<TResponse>>
        where TCommand : ICommand<TResponse>
    {
    }
}
EOF

    # IQueryHandler.cs
    cat <<EOF > src/Application/Abstractions/Messaging/IQueryHandler.cs
using MediatR;
using $PROJECT_NAME.Domain.Abstractions;

namespace $PROJECT_NAME.Application.Abstractions.Messaging
{
    public interface IQueryHandler<TQuery, TResponse> : IRequestHandler<TQuery, Result<TResponse>>
        where TQuery : IQuery<TResponse>
    {
    }
}
EOF

    # CreateSampleCommand.cs
    cat <<EOF > src/Application/Features/SampleFeature/CreateSampleCommand.cs
using $PROJECT_NAME.Application.Abstractions.Messaging;

namespace $PROJECT_NAME.Application.Features.SampleFeature
{
    public record CreateSampleCommand(string Name) : ICommand<int>;
}
EOF

    # CreateSampleCommandHandler.cs
    cat <<EOF > src/Application/Features/SampleFeature/CreateSampleCommandHandler.cs
using $PROJECT_NAME.Application.Abstractions.Messaging;
using $PROJECT_NAME.Domain.Abstractions;

namespace $PROJECT_NAME.Application.Features.SampleFeature
{
    public sealed class CreateSampleCommandHandler : ICommandHandler<CreateSampleCommand, int>
    {
        public async Task<Result<int>> Handle(CreateSampleCommand request, CancellationToken cancellationToken)
        {
            // TODO: Criar a entidade e salvar no banco de dados
            return Result.Success(1);
        }
    }
}
EOF

    # GetSampleQuery.cs
    cat <<EOF > src/Application/Features/SampleFeature/GetSampleQuery.cs
using $PROJECT_NAME.Application.Abstractions.Messaging;

namespace $PROJECT_NAME.Application.Features.SampleFeature
{
    public record GetSampleQuery(int Id) : IQuery<string>;
}
EOF

    # GetSampleQueryHandler.cs
    cat <<EOF > src/Application/Features/SampleFeature/GetSampleQueryHandler.cs
using $PROJECT_NAME.Application.Abstractions.Messaging;
using $PROJECT_NAME.Domain.Abstractions;

namespace $PROJECT_NAME.Application.Features.SampleFeature
{
    public sealed class GetSampleQueryHandler : IQueryHandler<GetSampleQuery, string>
    {
        public async Task<Result<string>> Handle(GetSampleQuery request, CancellationToken cancellationToken)
        {
            // TODO: Buscar do banco de dados
            return Result.Success("Sample Data");
        }
    }
}
EOF
  fi
}

generate_observability() {
  if [ "$OBSERVABILITY" == "yes" ]; then
    echo ""
    echo "🏢 Configurando Observability..."

    # Só gera Program.cs se Pipeline NÃO estiver ativo (Pipeline gera seu próprio Program.cs combinado)
    if [ "$PIPELINE" != "yes" ]; then
      generate_program_cs_observability
    fi

    generate_docker_compose
    generate_prometheus_config
  fi
}

generate_program_cs_observability() {
  echo ""
  echo "📝 Configurando OpenTelemetry no Program.cs..."

  if [ "$CQRS" == "yes" ]; then
    cat <<EOF > src/WebApi/Program.cs
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using $PROJECT_NAME.Application;
using $PROJECT_NAME.Infrastructure;
using $PROJECT_NAME.WebApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// OpenTelemetry Metrics
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource =>
        resource.AddService("$PROJECT_NAME.WebApi"))
    .WithMetrics(metrics =>
    {
        metrics.AddAspNetCoreInstrumentation();
        metrics.AddHttpClientInstrumentation();
        metrics.AddRuntimeInstrumentation();
        metrics.AddPrometheusExporter();
    });

var app = builder.Build();

app.UseExceptionHandler();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Prometheus scraping endpoint: /metrics
app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.Run();
EOF
  else
    cat <<EOF > src/WebApi/Program.cs
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using $PROJECT_NAME.Infrastructure;
using $PROJECT_NAME.WebApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// OpenTelemetry Metrics
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource =>
        resource.AddService("$PROJECT_NAME.WebApi"))
    .WithMetrics(metrics =>
    {
        metrics.AddAspNetCoreInstrumentation();
        metrics.AddHttpClientInstrumentation();
        metrics.AddRuntimeInstrumentation();
        metrics.AddPrometheusExporter();
    });

var app = builder.Build();

app.UseExceptionHandler();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Prometheus scraping endpoint: /metrics
app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.Run();
EOF
  fi
}

generate_docker_compose() {
  echo ""
  echo "🐳 Criando docker-compose.yml com Prometheus e Grafana..."

  cat <<EOF > docker-compose.yml
version: '3.9'

services:

  api:
    build:
      context: .
      dockerfile: src/WebApi/Dockerfile
    ports:
      - "5000:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_URLS=http://+:80

  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    depends_on:
      - api

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on:
      - prometheus
EOF
}

generate_prometheus_config() {
  echo ""
  echo "📄 Criando prometheus.yml..."

  cat <<EOF > prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: '$PROJECT_NAME-api'
    static_configs:
      - targets: ['api:80']
EOF
}

generate_pipeline_behaviors() {
  if [ "$PIPELINE" == "yes" ]; then
    echo ""
    echo "🧠 Configurando PIPELINE ENTERPRISE..."

    mkdir -p src/Application/Behaviors

    cat <<EOF > src/Application/Behaviors/CorrelationBehavior.cs
using MediatR;
using Microsoft.Extensions.Logging;

namespace $PROJECT_NAME.Application.Behaviors;

public sealed class CorrelationBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<CorrelationBehavior<TRequest, TResponse>> _logger;

    public CorrelationBehavior(
        ILogger<CorrelationBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var correlationId = Guid.NewGuid();

        using (_logger.BeginScope(new Dictionary<string, object>
        {
            ["CorrelationId"] = correlationId
        }))
        {
            return await next();
        }
    }
}
EOF

    cat <<EOF > src/Application/Behaviors/ValidationBehavior.cs
using FluentValidation;
using MediatR;

namespace $PROJECT_NAME.Application.Behaviors;

public sealed class ValidationBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (_validators.Any())
        {
            var context = new ValidationContext<TRequest>(request);

            var failures = _validators
                .Select(v => v.Validate(context))
                .SelectMany(r => r.Errors)
                .Where(f => f != null)
                .ToList();

            if (failures.Count != 0)
                throw new ValidationException(failures);
        }

        return await next();
    }
}
EOF

    cat <<EOF > src/Application/Behaviors/ExceptionHandlingBehavior.cs
using MediatR;
using Microsoft.Extensions.Logging;

namespace $PROJECT_NAME.Application.Behaviors;

public sealed class ExceptionHandlingBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<ExceptionHandlingBehavior<TRequest, TResponse>> _logger;

    public ExceptionHandlingBehavior(
        ILogger<ExceptionHandlingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        try
        {
            return await next();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Unhandled Exception for {RequestName}",
                typeof(TRequest).Name);

            throw;
        }
    }
}
EOF

    cat <<EOF > src/Application/Behaviors/LoggingBehavior.cs
using MediatR;
using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace $PROJECT_NAME.Application.Behaviors;

public sealed class LoggingBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling {RequestName}", typeof(TRequest).Name);

        var stopwatch = Stopwatch.StartNew();
        var response = await next();
        stopwatch.Stop();

        _logger.LogInformation("Handled {RequestName} in {ElapsedMilliseconds} ms", typeof(TRequest).Name, stopwatch.ElapsedMilliseconds);

        return response;
    }
}
EOF

    cat <<EOF > src/Application/Behaviors/PerformanceBehavior.cs
using MediatR;
using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace $PROJECT_NAME.Application.Behaviors;

public sealed class PerformanceBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<PerformanceBehavior<TRequest, TResponse>> _logger;

    public PerformanceBehavior(ILogger<PerformanceBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();

        var response = await next();

        stopwatch.Stop();

        if (stopwatch.ElapsedMilliseconds > 500)
        {
            _logger.LogWarning("Long Running Request: {Name} ({ElapsedMilliseconds} milliseconds) {@Request}",
                typeof(TRequest).Name, stopwatch.ElapsedMilliseconds, request);
        }

        return response;
    }
}
EOF

    cat <<EOF > src/Application/DependencyInjection.cs
using FluentValidation;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace $PROJECT_NAME.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(
        this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(
                Assembly.GetExecutingAssembly());

            cfg.AddOpenBehavior(typeof(
                Behaviors.CorrelationBehavior<,>));

            cfg.AddOpenBehavior(typeof(
                Behaviors.LoggingBehavior<,>));

            cfg.AddOpenBehavior(typeof(
                Behaviors.ValidationBehavior<,>));

            cfg.AddOpenBehavior(typeof(
                Behaviors.PerformanceBehavior<,>));

            cfg.AddOpenBehavior(typeof(
                Behaviors.ExceptionHandlingBehavior<,>));
        });

        services.AddValidatorsFromAssembly(
            Assembly.GetExecutingAssembly());

        return services;
    }
}
EOF

    if [ "$OBSERVABILITY" == "yes" ]; then
      # Program.cs com Pipeline + Observability (Prometheus + Grafana)
    cat <<EOF > src/WebApi/Program.cs
using Serilog;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using $PROJECT_NAME.Application;
using $PROJECT_NAME.Infrastructure;
using $PROJECT_NAME.WebApi.Infrastructure;

Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog();

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// OpenTelemetry - Tracing + Metrics (Prometheus)
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource =>
        resource.AddService("$PROJECT_NAME.WebApi"))
    .WithTracing(tracing =>
    {
        tracing.AddAspNetCoreInstrumentation();
        tracing.AddConsoleExporter();
    })
    .WithMetrics(metrics =>
    {
        metrics.AddAspNetCoreInstrumentation();
        metrics.AddHttpClientInstrumentation();
        metrics.AddRuntimeInstrumentation();
        metrics.AddPrometheusExporter();
    });

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Prometheus scraping endpoint: /metrics
app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.Run();
EOF

    else
      # Program.cs com Pipeline apenas (sem Observability)
    cat <<EOF > src/WebApi/Program.cs
using Serilog;
using OpenTelemetry.Trace;
using $PROJECT_NAME.Application;
using $PROJECT_NAME.Infrastructure;
using $PROJECT_NAME.WebApi.Infrastructure;

Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog();

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddOpenTelemetry()
    .WithTracing(tracing =>
    {
        tracing.AddAspNetCoreInstrumentation();
        tracing.AddConsoleExporter();
    });

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
EOF

    fi

  fi
}

generate_unit_of_work() {
  echo ""
  echo "📝 Criando Unit of Work..."

  mkdir -p src/Application/Repositories
  mkdir -p src/Infrastructure/Repositories

  # IUnitOfWork.cs
  cat <<EOF2 > src/Application/Repositories/IUnitOfWork.cs
namespace $PROJECT_NAME.Application.Repositories
{
    public interface IUnitOfWork
    {
        Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
        Task BeginTransactionAsync(CancellationToken cancellationToken = default);
        Task CommitAsync(CancellationToken cancellationToken = default);
        Task RollbackAsync(CancellationToken cancellationToken = default);
        IRepositoryBase<T> GetRepository<T>() where T : class;
    }
}
EOF2

  # UnitOfWork.cs
    cat <<EOF2 > src/Infrastructure/Repositories/UnitOfWork.cs
using $PROJECT_NAME.Application.Repositories;
using $PROJECT_NAME.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace $PROJECT_NAME.Infrastructure.Repositories
{
    public sealed class UnitOfWork : IUnitOfWork
    {
        private readonly AppDbContext _dbContext;
        private readonly Dictionary<Type, object> _repositories = new();
        private IDbContextTransaction? _currentTransaction;

        public UnitOfWork(AppDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return _dbContext.SaveChangesAsync(cancellationToken);
        }

        public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
        {
            if (_currentTransaction != null)
            {
                return;
            }

            _currentTransaction = await _dbContext.Database
                .BeginTransactionAsync(cancellationToken);
        }

        public async Task CommitAsync(CancellationToken cancellationToken = default)
        {
            if (_currentTransaction == null)
            {
                return;
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            await _currentTransaction.CommitAsync(cancellationToken);
            await _currentTransaction.DisposeAsync();
            _currentTransaction = null;
        }

        public async Task RollbackAsync(CancellationToken cancellationToken = default)
        {
            if (_currentTransaction == null)
            {
                return;
            }

            await _currentTransaction.RollbackAsync(cancellationToken);
            await _currentTransaction.DisposeAsync();
            _currentTransaction = null;
        }

        public IRepositoryBase<T> GetRepository<T>() where T : class
        {
            var type = typeof(T);

            if (_repositories.TryGetValue(type, out var repository))
            {
                return (IRepositoryBase<T>)repository;
            }

            var newRepository = new RepositoryBase<T>(_dbContext);
            _repositories[type] = newRepository;
            return newRepository;
        }
    }

    internal sealed class RepositoryBase<T> : IRepositoryBase<T> where T : class
    {
        private readonly AppDbContext _dbContext;
        private readonly DbSet<T> _dbSet;

        public RepositoryBase(AppDbContext dbContext)
        {
            _dbContext = dbContext;
            _dbSet = dbContext.Set<T>();
        }

        public Task<T> GetByIdAsync(int id)
        {
            return _dbSet.FindAsync(id).AsTask();
        }

        public async Task<IEnumerable<T>> GetAllAsync()
        {
            return await _dbSet.ToListAsync();
        }

        public async Task<bool> ExistsAsync(int id)
        {
            return await _dbSet.FindAsync(id) != null;
        }

        public Task AddAsync(T entity)
        {
            return _dbSet.AddAsync(entity).AsTask();
        }

        public Task UpdateAsync(T entity)
        {
            _dbSet.Update(entity);
            return Task.CompletedTask;
        }

        public Task DeleteAsync(T entity)
        {
            _dbSet.Remove(entity);
            return Task.CompletedTask;
        }

        public Task SaveChangesAsync()
        {
            return _dbContext.SaveChangesAsync();
        }
    }
}
EOF2
}

generate_exception_handler() {
  echo ""
  echo "🛡️ Criando Exception Handler..."

  mkdir -p src/WebApi/Infrastructure

  # GlobalExceptionHandler.cs
  cat <<EOF2 > src/WebApi/Infrastructure/GlobalExceptionHandler.cs
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace $PROJECT_NAME.WebApi.Infrastructure
{
    public sealed class GlobalExceptionHandler : IExceptionHandler
    {
        private readonly ILogger<GlobalExceptionHandler> _logger;

        public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
        {
            _logger = logger;
        }

        public async ValueTask<bool> TryHandleAsync(
            HttpContext httpContext,
            Exception exception,
            CancellationToken cancellationToken)
        {
            _logger.LogError(exception, "Exception occurred: {Message}", exception.Message);

            var problemDetails = new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Server error",
                Detail = exception.Message
            };

            httpContext.Response.StatusCode = problemDetails.Status.Value;
            await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

            return true;
        }
    }
}
EOF2
}

generate_mediatr_di() {
    if [ "$CQRS" == "yes" ] && [ "$PIPELINE" != "yes" ]; then
        echo ""
        echo "🧩 Configurando MediatR..."

        cat <<EOF2 > src/Application/DependencyInjection.cs
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace $PROJECT_NAME.Application;

public static class DependencyInjection
{
        public static IServiceCollection AddApplication(
                this IServiceCollection services)
        {
                services.AddMediatR(cfg =>
                {
                        cfg.RegisterServicesFromAssembly(
                                Assembly.GetExecutingAssembly());
                });

                return services;
        }
}
EOF2
    fi
}

generate_infrastructure_di() {
    echo ""
    echo "🔌 Configurando Infrastructure DI..."

    local provider_line=""

    if [ "$DATABASE" == "sqlserver" ]; then
        provider_line="options.UseSqlServer(connectionString);"
    else
        provider_line="options.UseNpgsql(connectionString);"
    fi

    cat <<EOF2 > src/Infrastructure/DependencyInjection.cs
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using $PROJECT_NAME.Application.Repositories;

namespace $PROJECT_NAME.Infrastructure;

public static class DependencyInjection
{
        public static IServiceCollection AddInfrastructure(
                this IServiceCollection services,
                IConfiguration configuration)
        {
                var connectionString = configuration.GetConnectionString("DefaultConnection");

                services.AddDbContext<AppDbContext>(options =>
                {
                        $provider_line
                });

                services.AddScoped<IUnitOfWork, Repositories.UnitOfWork>();

                return services;
        }
}
EOF2
}

generate_program_cs_base() {
    if [ "$PIPELINE" != "yes" ] && [ "$OBSERVABILITY" != "yes" ]; then
        echo ""
        echo "📝 Configurando Program.cs..."

        if [ "$CQRS" == "yes" ]; then
            cat <<EOF2 > src/WebApi/Program.cs
using $PROJECT_NAME.Application;
using $PROJECT_NAME.Infrastructure;
using $PROJECT_NAME.WebApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
        app.UseSwagger();
        app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
EOF2
        else
            cat <<EOF2 > src/WebApi/Program.cs
using $PROJECT_NAME.Infrastructure;
using $PROJECT_NAME.WebApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
        app.UseSwagger();
        app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
EOF2
        fi
    fi
}

generate_result_pattern() {
  echo ""
  echo "📦 Criando Result Pattern..."

  mkdir -p src/Domain/Abstractions
  mkdir -p src/WebApi/Controllers

  cat <<EOF > src/Domain/Abstractions/Error.cs
namespace \$PROJECT_NAME.Domain.Abstractions
{
    public enum ErrorType { NotFound, Validation, Unauthorized, ... }

    public record Error(string Id, ErrorType Type, string Description);

    // Some examples of errors
    public static class Errors
    {
        public static Error AccountNotFound { get; } = new("AccountNotFound", ErrorType.NotFound, "Account not found.");
        public static Error InsufficientFunds { get; } = new("InsufficientFunds", ErrorType.Validation, "Insufficient balance.");
    }
}
EOF

  cat <<EOF > src/Domain/Abstractions/Result.cs
namespace \$PROJECT_NAME.Domain.Abstractions
{
    public record Result
    {
        public bool IsSuccess { get; }
        public Error? Error { get; }

        protected Result(bool isSuccess, Error? error)
        {
            IsSuccess = isSuccess;
            Error = error;
        }

        public static Result Success() => new(true, null);
        public static Result Failure(Error error) => new(false, error ?? throw new ArgumentNullException(nameof(error)));

        public static implicit operator Result(Error error) => Failure(error);
    }

    public record Result<T> : Result
    {
        public T? Value { get; }

        private Result(T value) : base(true, null) => Value = value;
        private Result(Error error) : base(false, error) { }

        public static implicit operator Result<T>(T value) => new(value);

        public static implicit operator Result<T>(Error error) => new(error);
    }
}
EOF

  cat <<EOF > src/WebApi/Controllers/ApiController.cs
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using \$PROJECT_NAME.Domain.Abstractions;

namespace \$PROJECT_NAME.WebApi.Controllers
{
    [ApiController]
    public class ApiControllerBase : ControllerBase
    {
        protected IActionResult HandleFailure(Result result)
        {
            if (result.Error == null)
                return StatusCode(500, "An unknown error occurred.");

            return result.Error.Type switch
            {
                ErrorType.NotFound => NotFound(result.Error.Description),
                ErrorType.Validation => BadRequest(result.Error.Description),
                _ => StatusCode(500, result.Error.Description)
            };
        }
    }
}
EOF
}
