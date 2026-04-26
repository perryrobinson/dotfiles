---
title: Java Steering
description: Opinionated defaults for Java tooling through SDKMAN, Maven, Gradle, and Checkstyle.
applies_when:
  - Java project changes
  - Maven or Gradle work
  - Java linting or tests
tags:
  - java
  - sdkman
  - maven
  - gradle
  - checkstyle
---

# Java Steering

- Use SDKMAN-managed Java tooling on this machine.
- Use the repository's Maven or Gradle wrapper/configuration instead of introducing another build path.
- Use Checkstyle when present.
- Prefer the repo's existing `test`, `compile`, `check`, or equivalent targets before inventing new Java commands.
