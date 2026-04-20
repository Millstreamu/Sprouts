# Task 19 – End-to-end workflow tests (status)

## Current repository assessment

This repository is a Godot game project (`sprouts/project.godot`, `.tscn`, `.gd`) and does not contain:

- HTTP endpoints
- an `/ask` route
- order webhook handlers
- approval workflow action executors
- manager summary API endpoints
- Python/Node backend test harnesses (`pytest`, `jest`, etc.)

A code search for the requested business-flow identifiers returned no backend matches.

## Why implementation is blocked

The requested tests target backend API/business workflows that are not present in this codebase.
Without those services and persistence models, true end-to-end automation for the listed scenarios cannot be implemented in this repository.

## Proposed e2e strategy once backend code is available

Use a real app instance with a dedicated isolated test database and provider stubs:

1. **Test app bootstrapping**
   - Start app in test mode via fixture.
   - Inject test config (`ENV=test`, fake secrets, fake provider endpoints).
2. **Dedicated DB isolation**
   - Create per-test database/schema or transaction rollback fixture.
   - Seed inventory/agents/tasks fixtures via factories.
3. **External provider isolation**
   - Mock/stub all outbound HTTP/provider SDK calls.
   - Assert no real-network path is used during tests.
4. **E2E scenarios to add**
   - Order webhook: creates order, decrements inventory, writes agent log, creates PA follow-up when stock low.
   - `/ask`: routes stock question to `sales_inventory` and returns orchestrated final response.
   - Approval-required action: returns proposed action, no side-effect execution.
   - Manager summary: includes urgent items and open tasks.
5. **Maintainability**
   - Shared fixtures/factories for user/org/order/inventory/task entities.
   - Declarative assertions focused on externally observable behavior.
   - Avoid brittle internal implementation assertions.

## Validation status in this repository

No backend runtime or automated test framework exists in the current project, so backend e2e tests cannot be executed here.
