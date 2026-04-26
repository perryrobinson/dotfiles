# Frontend Steering

- Build the actual usable application experience first, not a marketing landing page, unless the user explicitly asks for a landing page.
- For operational tools, prefer dense, calm, task-focused UI over decorative marketing composition.
- Prefer SPA applications named or organized around `spa` unless the repo already has a different established frontend app shape.
- Use Bulletproof React conventions for feature organization, shared components, app providers, routing, and API boundaries.
- Prefer Vite, React, TanStack Router, TanStack Query, and Zod for new frontend app work.
- Never choose Next.js for new projects or rewrites unless explicitly instructed.
- Prefer modern CSS over Tailwind CSS v4 for new styling work unless the repo already depends on Tailwind.
- Use established project components and design conventions before adding new abstractions.
- Use icons for common tool actions when an icon library is already present.
- Verify responsive layout for text fit, overlapping UI, and primary workflows.
- For SPAs, prefer route-driven structure and data-loading patterns already established in the repo.
