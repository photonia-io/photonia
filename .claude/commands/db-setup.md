---
description: Set up or reset the database
---

Set up the database for development:

```bash
# Create database if it doesn't exist
bundle exec rails db:create

# Run migrations
bundle exec rails db:migrate

# Load schema (alternative to migrate)
# bundle exec rails db:schema:load

# Seed database with initial data (if needed)
# bundle exec rails db:seed
```

For a complete reset (⚠️ WARNING: destroys all data):

```bash
bundle exec rails db:drop db:create db:migrate
```
