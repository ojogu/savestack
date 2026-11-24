.PHONY: help migrate migrate-gen migrate-up deploy start stop restart logs rebuild/all

MESSAGE ?=
SERVICES := backend frontend worker celery-beat flower

help:
	@echo "SaveStack Makefile"
	@echo ""
	@echo "Migrations:"
	@echo "  make migrate MESSAGE='<msg>'   Generate and apply migration"
	@echo "  make migrate-gen MESSAGE='<msg>'  Generate migration only"
	@echo "  make migrate-up                Apply pending migrations"
	@echo ""
	@echo "Rebuild (build + restart):"
	@echo "  make rebuild/<service>         backend|frontend|worker|celery-beat|flower"
	@echo "  make rebuild/frontend/fresh    Rebuild frontend with --no-cache"
	@echo "  make rebuild/all               Rebuild all app services"
	@echo ""
	@echo "Deploy:"
	@echo "  make deploy                    Full deploy (down + rebuild all + up)"
	@echo ""
	@echo "Lifecycle:"
	@echo "  make start | stop | restart"
	@echo "  make logs                      Follow all logs"
	@echo "  make logs/<service>            Follow one service's logs"
	@echo "  make down/<service>            Stop one service"
	@echo ""
	@echo "Flower: http://127.0.0.1:5556"

# === Migrations ===

migrate:
ifndef MESSAGE
	@echo "ERROR: MESSAGE is required"
	@echo "Usage: make migrate MESSAGE='<description>'"
	@exit 1
endif
	cd backend && uv run alembic revision --autogenerate -m "$(MESSAGE)" && uv run alembic upgrade head

migrate-gen:
ifndef MESSAGE
	@echo "ERROR: MESSAGE is required"
	@echo "Usage: make migrate-gen MESSAGE='<description>'"
	@exit 1
endif
	cd backend && uv run alembic revision --autogenerate -m "$(MESSAGE)"

migrate-up:
	cd backend && uv run alembic upgrade head

# === Rebuild ===

rebuild/frontend/fresh:
	docker compose build --no-cache frontend
	docker compose up -d frontend

rebuild/%:
	docker compose up -d --build $*

rebuild/all: $(addprefix rebuild/,$(SERVICES))

# === Deploy ===

deploy: stop rebuild/all start

# === Container Lifecycle ===

start:
	docker compose up -d

stop:
	docker compose down

restart: stop start

logs:
	docker compose logs -f

logs/%:
	docker compose logs -f $*

down/%:
	docker compose stop $*
