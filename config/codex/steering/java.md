---
title: Java Steering
description: Opinionated defaults for Java tooling, Spring Boot services, build tools, tests, and style.
applies_when:
  - Java project setup
  - Java project changes
  - Spring Boot service development
  - Maven or Gradle work
  - Java linting or tests
tags:
  - java
  - sdkman
  - spring-boot
  - maven
  - gradle
  - checkstyle
  - junit
---

# Java Steering

- Use SDKMAN-managed Java tooling on this machine.
- Use the repository's Maven or Gradle wrapper/configuration instead of introducing another build path.
- Use Checkstyle when present.
- Prefer the repo's existing `test`, `compile`, `check`, or equivalent targets before inventing new Java commands.
- Prefer modern LTS Java versions when starting new work, unless the repo pins a different version.
- Prefer Spring Boot for Java service APIs unless the repo already uses another framework.
- Keep Java services layered and explicit: controller/resource, service/application, repository/gateway, configuration, and domain packages.
- Use constructor injection. Avoid field injection.
- Prefer records for immutable DTOs and value carriers.
- Use Jakarta validation annotations for request/config validation when applicable.
- Use typed configuration properties instead of scattered direct environment lookups.
- Prefer SLF4J-compatible structured logging. Do not use `System.out` for application logging.
- Use JUnit 5 for tests. Add focused unit tests for service logic and integration tests for framework/database boundaries.
- Do not mix Maven and Gradle in the same project unless the repository already does.
- Do not add Lombok by default. Prefer explicit Java language features unless the repo has already standardized on Lombok.
- Keep generated Java sources out of hand edits. Regenerate through the repo's build or codegen task.
