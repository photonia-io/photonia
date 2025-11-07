---
description: Start the development server
---

Start the Photonia development environment. This will run:
- Rails server (port 3000)
- Vite dev server (for Vue.js frontend)
- Sidekiq (background jobs)

If Overmind is available, use it:

```bash
overmind s -N -f Procfile.dev
```

Otherwise, provide instructions to run each service in separate terminals:

```bash
# Terminal 1: Rails server
bundle exec rails s

# Terminal 2: Vite dev server
bin/vite dev

# Terminal 3: Sidekiq
bundle exec sidekiq
```

Inform the user that the application will be available at http://localhost:3000
