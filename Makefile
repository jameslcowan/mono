.PHONY: help up down restart status logs \
        up-postgres down-postgres restart-postgres logs-postgres \
        up-postgrest down-postgrest restart-postgrest logs-postgrest \
        up-metabase down-metabase restart-metabase logs-metabase \
        up-pgadmin down-pgadmin restart-pgadmin logs-pgadmin \
        clean

COMPOSE := podman-compose

# Default target
help:
	@echo "Mono - Training Data Stack"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "All Services:"
	@echo "  up          Start all services"
	@echo "  down        Stop all services"
	@echo "  restart     Restart all services"
	@echo "  status      Show container status"
	@echo "  logs        Tail logs from all services"
	@echo ""
	@echo "Individual Services (postgres, postgrest, metabase, pgadmin):"
	@echo "  up-<svc>      Start a specific service"
	@echo "  down-<svc>    Stop a specific service"
	@echo "  restart-<svc> Restart a specific service"
	@echo "  logs-<svc>    Tail logs from a specific service"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean       Stop all and remove volumes (DESTRUCTIVE)"
	@echo ""
	@echo "Examples:"
	@echo "  make up"
	@echo "  make restart-postgres"
	@echo "  make logs-postgrest"

# === All Services ===

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart: down up

status:
	@podman ps -a --filter "name=mono_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs:
	$(COMPOSE) logs -f

# === Postgres ===

up-postgres:
	$(COMPOSE) up -d postgres

down-postgres:
	$(COMPOSE) stop postgres

restart-postgres: down-postgres up-postgres

logs-postgres:
	$(COMPOSE) logs -f postgres

# === PostgREST ===

up-postgrest:
	$(COMPOSE) up -d postgrest

down-postgrest:
	$(COMPOSE) stop postgrest

restart-postgrest: down-postgrest up-postgrest

logs-postgrest:
	$(COMPOSE) logs -f postgrest

# === Metabase ===

up-metabase:
	$(COMPOSE) up -d metabase

down-metabase:
	$(COMPOSE) stop metabase

restart-metabase: down-metabase up-metabase

logs-metabase:
	$(COMPOSE) logs -f metabase

# === pgAdmin ===

up-pgadmin:
	$(COMPOSE) up -d pgadmin

down-pgadmin:
	$(COMPOSE) stop pgadmin

restart-pgadmin: down-pgadmin up-pgadmin

logs-pgadmin:
	$(COMPOSE) logs -f pgadmin

# === Maintenance ===

clean:
	@echo "WARNING: This will delete all data volumes!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(COMPOSE) down -v
