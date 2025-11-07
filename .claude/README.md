# Claude Code Configuration

This directory contains Claude Code configuration for the Photonia project.

## Structure

```
.claude/
├── hooks/
│   └── SessionStart          # Runs when a new session starts
├── commands/                 # Custom slash commands
│   ├── test.md              # /test - Run RSpec tests
│   ├── js-test.md           # /js-test - Run JavaScript tests
│   ├── lint.md              # /lint - Run RuboCop linter
│   ├── format.md            # /format - Format code with Prettier
│   ├── start.md             # /start - Start development server
│   └── db-setup.md          # /db-setup - Set up database
└── README.md                # This file
```

## SessionStart Hook

The SessionStart hook automatically:
- Checks for Ruby and Node.js installations
- Installs Bundler and Yarn if needed
- Installs Ruby dependencies (bundle install)
- Installs JavaScript dependencies (yarn install)
- Verifies database and Redis connections
- Provides helpful quick start information

## Available Slash Commands

- **`/test`** - Run the RSpec test suite
- **`/js-test`** - Run JavaScript/Vue.js tests with Vitest
- **`/lint`** - Run RuboCop linter and offer to fix issues
- **`/format`** - Format code with Prettier
- **`/start`** - Start the development server (Rails, Vite, Sidekiq)
- **`/db-setup`** - Set up or reset the database

## Quick Start

When you start a new Claude Code session, the SessionStart hook will automatically prepare your environment. After that, you can:

1. Run tests: `/test` or `/js-test`
2. Check code quality: `/lint`
3. Start developing: `/start`

## Project-Specific Context

This is a Ruby on Rails 7 application with:
- **Backend**: Ruby 3, Rails 7, PostgreSQL, Redis, Sidekiq
- **Frontend**: Vue.js 3, Vite, JavaScript ES6+
- **API**: GraphQL
- **Testing**: RSpec (Ruby), Vitest (JavaScript)
- **Linting**: RuboCop (Ruby), Prettier (JavaScript)

See `.github/copilot-instructions.md` for comprehensive project documentation.
