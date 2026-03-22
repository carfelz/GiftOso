# Agent Guidelines for GiftOso Development

## Project Overview

GiftOso is a full-stack e-commerce application with:
- **storebackend**: Medusa v2 e-commerce API (Node.js)
- **storefront**: Next.js 15 storefront with Medusa JS SDK
- **services/logistics**: NestJS microservice for DR delivery operations

## Build/Lint/Test Commands

### Store Backend (Medusa)
```bash
cd storebackend
npm run build                    # Build Medusa project
npm run dev                      # Start development server (port 9000)
npm run seed                     # Seed database
npm run test:unit                # Run unit tests
npm run test:integration:http    # Run HTTP integration tests
npm run test:integration:modules # Run module integration tests
```

### Storefront (Next.js)
```bash
cd storefront
npm run dev                      # Start dev server (port 8000, Turbopack)
npm run build                    # Production build
npm run start                    # Start production server
npm run lint                     # ESLint check
npm run test                     # Run Jest tests
```

### Logistics Service (NestJS)
```bash
cd services/logistics
npm run build                    # Build NestJS project
npm run start                    # Start server (port 3001)
npm run dev                      # Watch mode with hot reload
npm run lint --fix               # ESLint with auto-fix
npm run test                     # Run all unit tests
npm run test:watch               # Watch mode for tests
npm run test:cov                 # Coverage report
npm run test:e2e                 # E2E tests (requires INTERNAL_API_KEY=test-api-key)
```

### Running a Single Test
```bash
# Logistics (NestJS) - use --testPathPattern
npm test -- --testPathPattern="deliverySlotsService.unit.spec.ts"

# Storefront - use --testNamePattern
npm test -- --testNamePattern="reserveSlot"

# Store Backend - use --testPathPattern with TEST_TYPE
TEST_TYPE=unit npm test -- --testPathPattern="my-test"
```

## Code Style Guidelines

### TypeScript Configuration

**Store Backend** (`storebackend/tsconfig.json`):
- Target: ES2021, decorators enabled
- Module: Node16
- `strictNullChecks: true`

**Storefront** (`storefront/tsconfig.json`):
- Strict mode enabled
- Path aliases: `@/*` → `src/*`, `@modules/*` → `src/modules/*`, `@lib/*` → `src/lib/*`

**Logistics** (`services/logistics/tsconfig.json`):
- `strictNullChecks: true`
- `noImplicitAny: true`
- Path aliases: `@/*` → `src/*`

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | kebab-case | `delivery-slots.service.ts` |
| Classes | PascalCase | `DeliverySlotsService` |
| Functions | camelCase | `reserveSlot()` |
| Constants | UPPER_SNAKE | `INTERNAL_API_KEY` |
| Types/Interfaces | PascalCase | `ReserveSlotResult` |
| Enums | PascalCase + UPPER values | `SlotStatus.AVAILABLE` |
| Directories | kebab-case | `deliverySlots/` |

### Import Organization

1. Node.js built-ins (none in ESM)
2. External packages (e.g., `@nestjs/common`, `next`)
3. Internal packages (e.g., `@medusajs/*`, `@lib/*`)
4. Relative imports

Example ordering:
```typescript
import { Controller, Post, Body } from "@nestjs/common"
import { ApiTags, ApiOperation } from "@nestjs/swagger"
import { DeliverySlotsService } from "./deliverySlotsService"
import { ReserveSlotDto } from "./dto/reserveSlotDto"
```

### Prettier Configuration

```json
{
  "arrowParens": "always",
  "semi": false,
  "endOfLine": "auto",
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "es5"
}
```

### ESLint Configuration

**Logistics Service** (`.eslintrc.json`):
- Extends: `@typescript-eslint/recommended`, `prettier/recommended`
- Disabled rules: `interface-name-prefix`, `explicit-function-return-type`, `explicit-module-boundary-types`, `no-explicit-any`

**Storefront** (`.eslintrc.js`):
- Extends: `next/core-web-vitals`

### Error Handling

**Backend (NestJS/Medusa)**:
- Use built-in exceptions: `NotFoundException`, `ConflictException`, `BadRequestException`
- Wrap external calls in try-catch with formatted errors
- Log errors with context using `Logger`

Example:
```typescript
try {
  return await this.client_.collection(collection).create(data)
} catch (error) {
  throw new MedusaError(
    MedusaError.Types.UNEXPECTED_STATE,
    this.formatStrapiError(error, `Failed to create ${collection}`)
  )
}
```

**Storefront (Next.js)**:
- Use React error boundaries for component errors
- Handle async errors with try-catch in server components
- Return `notFound()` for missing resources

### React/Next.js Patterns

**Server Components**: Default in Next.js 15 App Router
```typescript
export default async function Cart() {
  const cart = await retrieveCart()
  return <CartTemplate cart={cart} />
}
```

**Client Components**: Use `"use client"` directive sparingly
- Only for hooks (`useState`, `useEffect`) and browser APIs
- Keep client components small and focused

**State Management**: Zustand for global state
```typescript
import { create } from "zustand"
export const useStore = create((set) => ({ ... }))
```

### NestJS Patterns

**Services**: Use dependency injection via constructor
```typescript
@Injectable()
export class DeliverySlotsService {
  constructor(
    @InjectRepository(DeliverySlot)
    private readonly slotRepository: Repository<DeliverySlot>,
    @InjectQueue("delivery-slots")
    private readonly slotQueue: Queue,
  ) {}
}
```

**Controllers**: Use decorators for routing and Swagger docs
```typescript
@ApiTags("Logistics")
@ApiSecurity("x-api-key")
@UseGuards(ApiKeyGuard)
@Controller("v1/logistics")
export class DeliverySlotsController {
  @Post("reserve-slot")
  @ApiOperation({ summary: "Reserve a delivery slot" })
  async reserveSlot(@Body() dto: ReserveSlotDto) { ... }
}
```

**DTOs**: Use `class-validator` decorators for validation
```typescript
export class ReserveSlotDto {
  @IsString()
  zoneId: string
  
  @IsDateString()
  date: string
}
```

### Database & ORM

**Medusa Modules**: Use `@medusajs/framework/utils` `model.define()` for data models
```typescript
import { model } from "@medusajs/framework/utils"

const Post = model.define("post", {
  id: model.id().primaryKey(),
  title: model.text(),
})
```

**NestJS/Logistics**: Use TypeORM with decorators
```typescript
@Entity("delivery_slots")
export class DeliverySlot {
  @PrimaryGeneratedColumn("uuid")
  id: string
  
  @Column()
  zoneId: string
}
```

### Testing Patterns

**Unit Tests** (NestJS):
```typescript
describe("DeliverySlotsService", () => {
  let service: DeliverySlotsService
  
  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        DeliverySlotsService,
        { provide: getRepositoryToken(DeliverySlot), useValue: mockRepository },
      ],
    }).compile()
    service = module.get<DeliverySlotsService>(DeliverySlotsService)
  })
  
  it("should reserve an available slot", async () => { ... })
})
```

**Test File Locations**:
- NestJS: `src/**/__tests__/*.spec.ts` or `src/**/*.unit.spec.ts`
- Store Backend: `src/**/__tests__/*.unit.spec.ts`, `integration-tests/http/*.spec.ts`
- Storefront: `src/**/__tests__/*.test.ts(x)`

### Environment Variables

| Service | Key Variables |
|---------|---------------|
| Store Backend | `DATABASE_URL`, `REDIS_URL`, `INTERNAL_API_KEY`, `STRAPI_API_URL` |
| Storefront | `MEDUSA_BACKEND_URL`, `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY` |
| Logistics | `PORT`, `DATABASE_HOST`, `REDIS_URL`, `INTERNAL_API_KEY` |

### API Authentication

Logistics service endpoints (`/v1/logistics/*`) require `x-api-key` header.
Medusa admin routes require admin authentication.
Storefront uses Medusa JS SDK with publishable API key.

### Docker Services

- **postgres**: Port 5432 (default `postgres/postgres`)
- **redis**: Port 6379
- **medusa**: Port 9000
- **storefront**: Port 8000
- **cms** (Strapi): Port 1337
- **logistics** (NestJS): Port 3001

### Key Dependencies

| Service | Versions |
|---------|----------|
| Medusa | 2.13.1 |
| Next.js | 15.3.9 |
| NestJS | 10.x |
| TypeORM | 0.3.x |
| BullMQ | 5.x |
| Node.js | >=20 |

## Medusa Backend Development

For comprehensive backend patterns, see: `MEDUSA_DEVELOPMENT.md`

Key architecture: **Module → Workflow → API Route**
Critical rules: Use workflows for ALL mutations, never PUT/PATCH, prices stored as-is

## Reference Files

- `MEDUSA_DEVELOPMENT.md` - Comprehensive Medusa backend patterns
- Skill references: `reference/workflows.md`, `reference/api-routes.md`, `reference/querying-data.md`, etc.

## Next Steps After Implementation

After implementing backend features, always validate and test:

### 1. Run Build Validation
```bash
cd storebackend && npm run build
```
Fix any type errors before proceeding.

### 2. Start the Development Server
```bash
cd storebackend && npm run dev
```

### 3. Access the Admin Dashboard
http://localhost:9000/app

### 4. Test API Routes

**Admin Routes** (require authentication):
```bash
# POST example
curl -X POST http://localhost:9000/admin/[route] \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"

# GET example
curl http://localhost:9000/admin/[route] \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Store Routes**:
```bash
curl -X POST http://localhost:9000/store/[route] \
  -H "Content-Type: application/json" \
  -H "x-publishable-api-key: YOUR_KEY"
```

### 5. What to Test
- **Workflows:** Verify mutation operations and rollback on errors
- **Subscribers:** Trigger events and check logs
- **Scheduled jobs:** Check logs for cron output
