# Medusa Backend Development Guide

Comprehensive backend development patterns for Medusa v2 applications.

## When to Apply

Use this guide for ANY backend development task:
- Creating or modifying custom modules and data models
- Implementing workflows for mutations
- Building API routes (store or admin)
- Defining module links between entities
- Writing business logic or validation
- Querying data across modules
- Adding authentication

## Architecture Pattern

**ALWAYS follow this flow - never bypass layers:**

```
Module (data models + CRUD operations)
  ↓ used by
Workflow (business logic + mutations with rollback)
  ↓ executed by
API Route (HTTP interface, validation middleware)
  ↓ called by
Frontend (admin dashboard/storefront via SDK)
```

**Key conventions:**
- Only GET, POST, DELETE methods (never PUT/PATCH)
- Workflows are required for ALL mutations
- Business logic belongs in workflow steps, NOT routes
- Query with `query.graph()` for cross-module data retrieval
- Query with `query.index()` (Index Module) for filtering across linked modules
- Module links maintain isolation between modules

## Critical Rules by Priority

### 1. Architecture Violations (CRITICAL)

| Rule | Description |
|------|-------------|
| `arch-workflow-required` | Use workflows for ALL mutations, never call module services from routes |
| `arch-layer-bypass` | Never bypass layers (route → service without workflow) |
| `arch-http-methods` | Use only GET, POST, DELETE (never PUT/PATCH) |
| `arch-module-isolation` | Use module links, not direct cross-module service calls |
| `arch-query-config-fields` | Don't set explicit `fields` when using `req.queryConfig` |

### 2. Type Safety (CRITICAL)

| Rule | Description |
|------|-------------|
| `type-request-schema` | Pass Zod inferred type to `MedusaRequest<T>` when using `req.validatedBody` |
| `type-authenticated-request` | Use `AuthenticatedMedusaRequest` for protected routes (not `MedusaRequest`) |
| `type-export-schema` | Export both Zod schema AND inferred type from middlewares |
| `type-linkable-auto` | Never add `.linkable()` to data models (automatically added) |
| `type-module-name-camelcase` | Module names MUST be camelCase, never use dashes (causes runtime errors) |

### 3. Business Logic Placement (HIGH)

| Rule | Description |
|------|-------------|
| `logic-workflow-validation` | Put business validation in workflow steps, not API routes |
| `logic-ownership-checks` | Validate ownership/permissions in workflows, not routes |
| `logic-module-service` | Keep modules simple (CRUD only), put logic in workflows |

### 4. Import & Code Organization (HIGH)

| Rule | Description |
|------|-------------|
| `import-top-level` | Import workflows/modules at file top, never use `await import()` in route body |
| `import-static-only` | Use static imports for all dependencies |
| `import-no-dynamic-routes` | Dynamic imports add overhead and break type checking |

### 5. Data Access Patterns (MEDIUM)

| Rule | Description |
|------|-------------|
| `data-price-format` | **CRITICAL**: Prices stored as-is in Medusa (49.99 stored as 49.99, NOT in cents). Never multiply by 100 |
| `data-query-method` | Use `query.graph()` for retrieving data; use `query.index()` for filtering across linked modules |
| `data-query-graph` | Use `query.graph()` for cross-module queries with dot notation |
| `data-query-index` | Use `query.index()` when filtering by properties of linked data models in separate modules |
| `data-list-and-count` | Use `listAndCount` for single-module paginated queries |
| `data-linked-filtering` | `query.graph()` can't filter by linked module fields - use `query.index()` |
| `data-no-js-filter` | Don't use JavaScript `.filter()` on linked data - use database filters |
| `data-auth-middleware` | Trust `authenticate` middleware, don't manually check `req.auth_context` |

### 6. File Organization (MEDIUM)

| Rule | Description |
|------|-------------|
| `file-workflow-steps` | Create steps in `src/workflows/steps/[name].ts` |
| `file-workflow-composition` | Composition functions in `src/workflows/[name].ts` |
| `file-middleware-exports` | Export schemas and types from middleware files |
| `file-links-directory` | Define module links in `src/links/[name].ts` |

## Workflow Composition Rules

**The workflow function has critical constraints:**

```typescript
// ✅ CORRECT
const myWorkflow = createWorkflow(
  "my-workflow",
  function (input: MyInput) {
    const stepResult = myStep(input)
    return new WorkflowResponse(stepResult)
  }
)

// ❌ WRONG - Don't do these
const myWorkflow = createWorkflow(
  "my-workflow",
  async (input) => {              // ❌ No async
    const result = await myStep() // ❌ No await
    return new WorkflowResponse(result)
  }
)

// ❌ WRONG - Use when() for conditionals
const myWorkflow = createWorkflow(
  "my-workflow",
  function (input) {
    if (input.condition) {        // ❌ No conditionals
      const result = stepA(input)
    } else {
      const result = stepB(input)
    }
    return new WorkflowResponse(result)
  }
)
```

**Constraints:**
- No async/await (runs at load time)
- No arrow functions (use `function`)
- No conditionals/ternaries (use `when()`)
- No variable manipulation (use `transform()`)
- Multiple step calls need `.config({ name: "unique-name" })`

## Common Mistakes Checklist

Before marking tasks complete, verify:

**Architecture:**
- [ ] Calling module services directly from API routes
- [ ] Using PUT or PATCH methods
- [ ] Bypassing workflows for mutations
- [ ] Setting `fields` explicitly with `req.queryConfig`

**Type Safety:**
- [ ] Forgetting `MedusaRequest<T>` type argument
- [ ] Using `MedusaRequest` instead of `AuthenticatedMedusaRequest` for protected routes
- [ ] Adding `.linkable()` to data models
- [ ] Using dashes in module names (must be camelCase)

**Business Logic:**
- [ ] Validating business rules in API routes
- [ ] Manually checking `req.auth_context?.actor_id`

**Imports:**
- [ ] Using `await import()` in route handler bodies

**Data Access:**
- [ ] **CRITICAL**: Multiplying prices by 100 (prices are stored as-is: 49.99 = 49.99)
- [ ] Filtering by linked module fields with `query.graph()`
- [ ] Using JavaScript `.filter()` on linked data

## Data Model Patterns

**Medusa Modules**: Use `@medusajs/framework/utils` `model.define()`
```typescript
import { model } from "@medusajs/framework/utils"

const Post = model.define("post", {
  id: model.id().primaryKey(),
  title: model.text(),
  content: model.text(),
})
```

**NestJS/Logistics** (separate service): Use TypeORM with decorators
```typescript
import { Entity, PrimaryGeneratedColumn, Column } from "typeorm"

@Entity("delivery_slots")
export class DeliverySlot {
  @PrimaryGeneratedColumn("uuid")
  id: string
  
  @Column()
  zoneId: string
}
```

## Query Patterns

**Cross-module query with query.graph():**
```typescript
const result = await query.graph({
  entity: "order",
  fields: ["id", "total", "customer.*"],
  filters: { id: orderId },
})
```

**Filtering across linked modules (use query.index()):**
```typescript
const result = await query.index({
  entity: "order",
  filters: { "fulfillment_status": ["not-fulfilled"] },
})
```

## Reference Files

For detailed patterns, see these skill reference files:
- `reference/custom-modules.md` - Module creation patterns
- `reference/workflows.md` - Workflow and step patterns
- `reference/api-routes.md` - Route structure and validation
- `reference/module-links.md` - Cross-module entity linking
- `reference/querying-data.md` - Query patterns and filtering
- `reference/authentication.md` - Route protection
- `reference/error-handling.md` - Error patterns
- `reference/scheduled-jobs.md` - Cron jobs
- `reference/subscribers-and-events.md` - Event handling
- `reference/troubleshooting.md` - Common errors

## Key Dependencies

| Package | Version |
|---------|---------|
| Medusa | 2.13.1 |
| Node.js | >=20 |
| TypeScript | 5.x |
