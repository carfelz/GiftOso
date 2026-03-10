# Changelog

All notable changes to the GiftOso project will be documented in this file.

## [Unreleased] - 2026-03-09

### Added

- **Storefront Thoughtfully Redesign** (`storefront/`)
  - Redesigned the storefront to mirror thoughtfully.com UI/UX.
  - Implemented a full-bleed Hero banner and created a new visual Categories component (`src/modules/home/components/categories/index.tsx`).
  - Added an announcement bar and integrated the GiftOso brand identity with Red Panda logo styling into the global Navigation.
  - Retweaked `ProductRail` and `Thumbnail` layouts for a cleaner, premium flat presentation.
  - Streamlined the global Footer content for GiftOso.

- **Storefront "Liquid Glass" Revamp** (`storefront/`)
  - Implemented the 'Liquid Glass' UI aesthetics with Bamboo Cream, Pandas Rust, and Deep Slate colors and `glass-panel` utility.
  - Built core branded components: `ZoomImage`, `ProductModal`, "Wink" Nav Header, and `ProductCarousel` with Swiper.
  - Integrated Red Panda easter eggs: Empty Cart message, Gift Assistant FAB, and Order Success Celebration.
  - Re-designed checkout UI with a custom Gift Wizard Stepper built on top of MUI `<Stepper>`.
  - Outfitted `storefront/` project with Jest + React Testing Library testing suite.

- **NestJS Logistics Microservice** (`services/logistics/`)
  - `POST /v1/logistics/validate-address` — DR sector validation (Piantini, Naco, Gurabo)
  - `GET /v1/logistics/shipping-options` — Zone-based rate calculation with pantry proximity
  - `POST /v1/logistics/reserve-slot` — Delivery slot reservation with BullMQ expiry
  - `POST /v1/logistics/release-slot` — Saga compensation slot release
  - `POST /v1/logistics/dispatch` — Mock courier dispatch (PedidosYa / Manual)
  - `GET /health` — Service health check (Terminus + DB ping)
  - TypeORM entities: `geo_zones`, `delivery_slots` in `logistics` schema
  - Seed data: 3 DR zones + 7 days of time slots
  - Swagger/OpenAPI documentation at `/api-docs`
  - `INTERNAL_API_KEY` header guard on all logistics endpoints
  - Dockerfile for development
  - Unit tests for all services and controllers

- **Medusa v2 GiftingModule** (`storebackend/src/modules/gifting/`)
  - DML model: `giftingData` (recipientName, recipientPhone, videoUrl, deliveryId, deliveryStatus)
  - `GiftingModuleService` with auto-generated CRUD via `MedusaService`
  - Registered in `medusa-config.ts`

- **Order–Gifting Remote Link** (`storebackend/src/links/orderGiftingLink.ts`)
  - `defineLink(Order, GiftingData)` for binding orders to recipient metadata

- **`place-gift-order-workflow`** (`storebackend/src/workflows/placeGiftOrder/`)
  - Step 1: `validateLogisticsStep` — Address validation via logistics service
  - Step 2: `reserveDeliveryStep` — Slot reservation with saga compensation
  - Step 3: `createOrderStep` — Medusa order creation (placeholder)
  - Step 4: `linkGiftingDataStep` — Links GiftingData to Order via Medusa Linker
  - Step 5: `emitOrderPlacedStep` — Emits `order.gift_placed` event (Pub/Sub stub)

- **API Routes**
  - `POST /store/gift-order` — Triggers full gift order workflow with health-check gate
  - `GET /admin/gifting-data` — Lists all gifting records

- **Docker Compose** — Added `giftoso_logistics` container with env vars
- **axios** — Added to storebackend for service-to-service HTTP calls with `INTERNAL_API_KEY`

### Changed

- Updated `medusa-config.ts` to register GiftingModule and add `redisUrl`
- Updated `docker-compose.yml` with logistics service, `LOGISTICS_SERVICE_URL`, and `INTERNAL_API_KEY`
- Updated `README.md` with new services, endpoints, environment variables, and commands
