# GiftOso

Welcome to the **GiftOso** project repository! This project consists of a full-stack e-commerce application built with a Medusa backend and a Next.js storefront, designed with microservices in mind.

## Project Structure

- `store-backend`: The core e-commerce API built on Medusa (Node.js).
- `storefront`: The user-facing web application built with Next.js.

## Prerequisites
- Docker & Docker Compose
- Node.js & npm (for local non-Docker development)

## Getting Started

The entire project is containerized and orchestrated using Docker Compose from the root directory.

### 1. Initialize the Project

Because `store-backend` and `storefront` are developed in their own respective repositories, you must first initialize this root orchestrator to pull them down.

Run the following command in your terminal from the root directory:

```bash
./init.sh
```

### 2. Configure Environment

1. Copy `.env.template` to `.env` in `store-backend`.
2. Ensure you have the `.env.local` configured in `storefront`.
3. From the root directory (`/Users/carlosfeliz/code/GiftOso`), build and start the containers:

```bash
docker compose up -d --build
```

This will spin up:
- PostgreSQL database (`medusa_postgres` / `:5432`)
- Redis cache (`medusa_redis` / `:6379`)
- Medusa API (`giftoso_backend` / `:9000`)
- Next.js Storefront (`giftoso_storefront` / `:8000`)

### Stopping the Project

```bash
docker compose down
```

## Microservices Architecture

The system is configured to support future microservices via a shared Docker network (`giftoso_network`). Any new service can easily be added to the `docker-compose.yml` file and join this network to communicate with the rest of the application.
