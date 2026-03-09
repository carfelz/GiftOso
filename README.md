# GiftOso

Welcome to the **GiftOso** project repository! This project consists of a full-stack e-commerce application built with a Medusa backend and a Next.js storefront, designed with microservices in mind.

## Project Structure

- `storebackend`: The core e-commerce API built on Medusa v2 (Node.js).
- `storefront`: The user-facing web application built with Next.js.
- `services/logistics`: NestJS-based logistics microservice for DR delivery operations.

## Prerequisites
- Docker & Docker Compose
- Node.js >= 20 & npm (for local non-Docker development)

## Getting Started

The entire project is containerized and orchestrated using Docker Compose from the root directory.

### 1. Initialize the Project

Because `storebackend` and `storefront` are developed in their own respective repositories, you must first initialize this root orchestrator to pull them down.

Run the following command in your terminal from the root directory:

```bash
./init.sh
```

### 2. Configure Environment

1. Copy `.env.template` to `.env` in `storebackend`.
2. Ensure you have the `.env.local` configured in `storefront`.
3. Copy `services/logistics/.env.example` to `services/logistics/.env` and adjust values if needed.
4. Optionally set `INTERNAL_API_KEY` in your shell or a root `.env` file (defaults to `giftoso-internal-secret-key`).
5. From the root directory, build and start the containers:

```bash
docker compose up -d --build
```

This will spin up:
- PostgreSQL database (`giftoso_postgres` / `:5432`)
- Redis cache (`giftoso_redis` / `:6379`)
- Medusa API (`giftoso_backend` / `:9000`)
- Next.js Storefront (`giftoso_storefront` / `:8000`)
- **Logistics Service** (`giftoso_logistics` / `:3001`)

### 3. Seed Logistics Data

After the containers are running, seed the DR delivery zones and time slots:

```bash
docker exec -it giftoso_logistics npm run seed
```

### 4. View Logistics API Docs

Open [http://localhost:3001/api-docs](http://localhost:3001/api-docs) to view the Swagger UI for all logistics endpoints.

### Stopping the Project

```bash
docker compose down
```

## Services & Endpoints

### Medusa Store Backend (`:9000`)
- `POST /store/gift-order` — Place a gift order (triggers the full logistics workflow)
- `GET /admin/gifting-data` — List all gifting data records (admin)

### Logistics Microservice (`:3001`)
- `GET /health` — Health check
- `POST /v1/logistics/validate-address` — Validate DR sectors and return a `zone_id`
- `GET /v1/logistics/shipping-options?zoneId=X` — Get shipping rates for a zone
- `POST /v1/logistics/reserve-slot` — Reserve a delivery time slot
- `POST /v1/logistics/release-slot` — Release a reserved slot (saga compensation)
- `POST /v1/logistics/dispatch` — Trigger courier dispatch (mock)
- `GET /v1/logistics/zones` — List all active geo zones
- `GET /v1/logistics/available-slots?zoneId=X&date=Y` — List available slots

> **Note:** All `/v1/logistics/*` endpoints require the `x-api-key` header.

## Environment Variables

| Variable | Service | Description |
|---|---|---|
| `DATABASE_URL` | medusa | PostgreSQL connection string |
| `REDIS_URL` | medusa, logistics | Redis connection string |
| `LOGISTICS_SERVICE_URL` | medusa | URL of the logistics service (e.g. `http://logistics:3001`) |
| `INTERNAL_API_KEY` | medusa, logistics | Shared API key for service-to-service auth |
| `DATABASE_SCHEMA` | logistics | PostgreSQL schema name (default: `logistics`) |

## Microservices Architecture

The system is configured to support microservices via a shared Docker network (`giftoso_network`). Any new service can easily be added to the `docker-compose.yml` file and join this network to communicate with the rest of the application.

### Gift Order Workflow

The `place-gift-order-workflow` executes the following steps:

1. **Validate Address** → Calls logistics `/validate-address`
2. **Reserve Delivery Slot** → Calls logistics `/reserve-slot` (with saga rollback)
3. **Create Order** → Standard Medusa order creation
4. **Link Gifting Data** → Binds recipient metadata to the order
5. **Emit Event** → Publishes `order.gift_placed` for async dispatch

If any step fails after slot reservation, the workflow automatically releases the slot (Saga Pattern).

## Development

### Running Tests

**Logistics Service:**
```bash
cd services/logistics && npm test       # Unit tests
cd services/logistics && npm run test:e2e # E2E tests
```

**Medusa Backend:**
```bash
cd storebackend && npm run test:unit
```

### Dependencies

- **Medusa v2**: `2.13.1`
- **NestJS**: `10.x`
- **TypeORM**: `0.3.x`
- **BullMQ**: `5.x`
- **axios**: HTTP client for service-to-service calls
