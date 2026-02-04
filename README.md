# Mono

A local development stack for managing LLM training data, featuring a PostgreSQL database with an auto-generated REST API, analytics dashboard, and database management UI.

## Services

| Service    | Port | URL                        | Description                          |
|------------|------|----------------------------|--------------------------------------|
| PostgreSQL | 5432 | `localhost:5432`           | Primary database                     |
| PostgREST  | 3000 | http://localhost:3000      | Auto-generated REST API              |
| Metabase   | 3001 | http://localhost:3001      | Analytics and data visualization     |
| pgAdmin    | 5050 | http://localhost:5050      | Database management UI               |

## Prerequisites

- [Podman](https://podman.io/) and [podman-compose](https://github.com/containers/podman-compose)
- Or Docker and docker-compose (change `COMPOSE` variable in Makefile)

## Quick Start

```bash
# Copy environment file and configure
cp .env.example .env
# Edit .env with your credentials

# Start all services
make up

# Check status
make status
```

## Commands

Run `make help` to see all available commands.

### All Services

```bash
make up        # Start all services
make down      # Stop all services
make restart   # Restart all services
make status    # Show container status
make logs      # Tail logs from all services
```

### Individual Services

Replace `<service>` with: `postgres`, `postgrest`, `metabase`, or `pgadmin`

```bash
make up-<service>       # Start a specific service
make down-<service>     # Stop a specific service
make restart-<service>  # Restart a specific service
make logs-<service>     # Tail logs from a specific service
```

Examples:
```bash
make restart-postgres
make logs-postgrest
make up-metabase
```

### Maintenance

```bash
make clean    # Stop all and remove volumes (DESTRUCTIVE - deletes all data)
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable           | Description                              |
|--------------------|------------------------------------------|
| `POSTGRES_USER`    | Database username                        |
| `POSTGRES_PASSWORD`| Database password                        |
| `POSTGRES_DB`      | Database name                            |
| `JWT_SECRET`       | PostgREST JWT secret (min 32 chars)      |

### Generating a JWT Secret

```bash
openssl rand -base64 32
```

## Database Schema

The database is initialized with a `training_samples` table in the `api` schema:

| Column            | Type         | Description                        |
|-------------------|--------------|------------------------------------|
| `id`              | UUID         | Primary key (auto-generated)       |
| `system_prompt`   | TEXT         | System prompt for the LLM          |
| `user_input`      | TEXT         | User input (required)              |
| `assistant_output`| TEXT         | Assistant response (required)      |
| `model_used`      | VARCHAR(100) | Model identifier                   |
| `use_case`        | VARCHAR(100) | Use case category                  |
| `tags`            | TEXT[]       | Array of tags                      |
| `quality_score`   | INTEGER      | Rating 1-5                         |
| `is_approved`     | BOOLEAN      | Approval status                    |
| `created_at`      | TIMESTAMPTZ  | Creation timestamp                 |
| `updated_at`      | TIMESTAMPTZ  | Last update timestamp              |

## Using the REST API

PostgREST automatically generates REST endpoints from database tables.

### Examples

```bash
# Get all training samples
curl http://localhost:3000/training_samples

# Get approved samples only
curl http://localhost:3000/training_samples?is_approved=eq.true

# Get samples by use case
curl http://localhost:3000/training_samples?use_case=eq.customer-support

# Insert a new sample
curl -X POST http://localhost:3000/training_samples \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "How do I reset my password?",
    "assistant_output": "You can reset your password by clicking...",
    "use_case": "customer-support",
    "quality_score": 4
  }'

# Update a sample
curl -X PATCH "http://localhost:3000/training_samples?id=eq.<uuid>" \
  -H "Content-Type: application/json" \
  -d '{"is_approved": true}'

# Use the approved_training_data view for exports
curl http://localhost:3000/approved_training_data
```

See the [PostgREST documentation](https://postgrest.org/en/stable/api.html) for full query syntax.

## Connecting to Services

### pgAdmin

1. Open http://localhost:5050
2. Default credentials: `admin@local.dev` / `admin` (or as configured in `.env`)
3. Add a new server:
   - Host: `172.20.0.10` (or `mono_postgres`)
   - Port: `5432`
   - Username/Password: from your `.env`

### Metabase

1. Open http://localhost:3001
2. Complete the setup wizard
3. Add PostgreSQL as a data source:
   - Host: `172.20.0.10`
   - Port: `5432`
   - Database: from your `.env`

### Direct PostgreSQL Connection

```bash
psql -h localhost -p 5432 -U <POSTGRES_USER> -d <POSTGRES_DB>
```

## Data Persistence

Data is stored in named volumes and persists across restarts:

- `postgres_data` - Database files
- `pgadmin_data` - pgAdmin configuration
- `metabase_data` - Metabase configuration

To completely reset (delete all data):
```bash
make clean
```

## Network

Services communicate on a bridge network (`172.20.0.0/16`) with static IPs:

| Service    | IP Address    |
|------------|---------------|
| PostgreSQL | 172.20.0.10   |
| PostgREST  | 172.20.0.11   |
| Metabase   | 172.20.0.12   |
| pgAdmin    | 172.20.0.13   |

## Adding New Tables

1. Create a new migration file in `migrations/` (e.g., `002_new_table.sql`)
2. Add the table to the `api` schema for automatic REST API exposure
3. Grant appropriate permissions to `anon` and/or `authenticated` roles
4. Run `make clean && make up` to reinitialize (or apply manually via psql/pgAdmin)

## Troubleshooting

### Containers won't start
```bash
# Check logs for errors
make logs

# Ensure ports aren't in use
sudo lsof -i :5432 -i :3000 -i :3001 -i :5050
```

### PostgREST can't connect to Postgres
```bash
# Ensure Postgres is healthy
make status

# Restart PostgREST after Postgres is ready
make restart-postgrest
```

### Reset everything
```bash
make clean
make up
```
