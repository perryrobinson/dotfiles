---
title: Codegen Steering
description: Opinionated defaults for generated code and freshness checks.
applies_when:
  - Generated code changes
  - OpenAPI, protobuf, route tree, or API client updates
  - Codegen drift or freshness checks
tags:
  - codegen
  - generated-code
  - openapi
  - protobuf
---

# Codegen Steering

- Treat generated code as derived output.
- Do not hand-edit generated clients, protobuf stubs, route trees, OpenAPI output, or similar artifacts.
- Find and run the owning codegen command instead.
- After codegen, inspect the generated diff and verify it is limited to expected outputs.
- If an API schema changes, check downstream generated clients and freshness checks.
