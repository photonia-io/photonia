# Copilot Instructions for Photonia

## Project Overview

Photonia is a self-hosted photo sharing web application that allows users to store, organize, and share their photos. The application leverages AI-powered photo recognition to automatically create labels and tags, making photo discovery and organization seamless.

### Key Features

- Photo storage on Amazon S3
- AI-powered photo labeling using Amazon Rekognition
- Smart thumbnail generation based on photo content
- Flickr import functionality for migrating existing photo collections
- Full-text search capabilities
- User management and authentication
- Responsive web interface

## Architecture & Technology Stack

### Backend

- **Ruby on Rails 7.0** - Main web framework
- **Ruby 3.4.3** - Programming language
- **PostgreSQL** - Primary database
- **Redis** - Caching and session storage
- **Sidekiq** - Background job processing
- **GraphQL** - API layer for frontend communication
- **Shrine** - File upload handling
- **Devise + JWT** - Authentication system

### Frontend

- **Vue.js 3** - JavaScript framework
- **Vite** - Build tool and development server
- **JavaScript ES6+** - Modern JavaScript with ES modules
- **Bulma** - CSS framework
- **Apollo Client** - GraphQL client
- **Pinia** - State management
- **Chart.js** - Data visualization

### External Services

- **Amazon S3** - Photo storage
- **Amazon Rekognition** - AI-powered image analysis
- **Sentry** - Error monitoring

### Development Tools

- **RuboCop** - Ruby code linting
- **RSpec** - Ruby testing framework
- **Vitest** - JavaScript testing framework
- **Prettier** - Code formatting
- **Overmind** - Process management

## Project Structure

```
/
├── app/
│   ├── controllers/        # Rails controllers
│   ├── models/            # ActiveRecord models
│   ├── graphql/           # GraphQL schema and resolvers
│   ├── javascript/        # Vue.js frontend application
│   ├── jobs/              # Sidekiq background jobs
│   ├── policies/          # Pundit authorization policies
│   ├── services/          # Business logic services
│   ├── uploaders/         # Shrine uploaders
│   └── views/             # Rails views
├── config/                # Rails configuration
├── db/                    # Database migrations and schema
├── spec/                  # RSpec tests
├── lib/                   # Library code
└── public/                # Static assets
```

## Development Workflow

### Setup Requirements

```bash
# System dependencies
sudo apt install libpq-dev libexif-dev imagemagick

# Install Ruby dependencies
bundle install

# Install JavaScript dependencies
yarn install
```

### Running the Application

```bash
# Option 1: Separate terminals
bin/rails s              # Rails server (port 3000)
bin/vite dev            # Vite dev server
bundle exec sidekiq     # Background jobs

# Option 2: Using Overmind (recommended)
overmind s -N -f Procfile.dev
```

### Testing

```bash
# Ruby tests
bundle exec rspec

# JavaScript tests
npm run test:run

# System tests (requires Docker setup)
# See README.md for Selenium Grid setup
```

### Code Quality

```bash
# Ruby linting
bundle exec rubocop

# JavaScript formatting
npx prettier --write .
```

## Key Models and Components

### Core Models

- **User** - User accounts with Devise authentication
- **Photo** - Main photo model with metadata and processing
- **Album** - Photo collections
- **Comment** - Photo comments
- **Label** - AI-generated photo labels from Rekognition
- **Tag** - User-defined photo tags

### Important Services

- **PhotoProcessingService** - Handles photo upload and processing
- **RekognitionService** - Interfaces with AWS Rekognition
- **FlickrImportService** - Imports photos from Flickr

### Background Jobs

- **RekognitionJob** - Processes photos with AI labeling
- **PromoteJob** - Handles photo upload promotion
- **AddIntelligentDerivativesJob** - Generates thumbnails and derivatives
- **SitemapRefreshJob** - Updates XML sitemap
- **DestroyJob** - Handles resource cleanup
- **FlickrPeopleGetInfoJob** - Fetches Flickr user information

### Frontend Structure

- **app.vue** - Main application component
- **stores/** - Pinia state management
- **entrypoints/** - Vite entry points
- **photos/**, **albums/**, **users/** - Domain-specific components

## Coding Conventions

### Ruby/Rails

- Follow RuboCop configuration in `.rubocop.yml`
- Use frozen string literals
- Prefer explicit returns
- Use service objects for complex business logic
- Follow Rails naming conventions

### JavaScript/Vue.js

- Use modern JavaScript ES6+ features
- Follow Vue.js 3 Composition API patterns
- Use Pinia for state management
- Follow ESLint and Prettier configurations

### GraphQL

- Define types in `app/graphql/types/`
- Implement resolvers in `app/graphql/resolvers/`
- Mutations in `app/graphql/mutations/`
- Queries in `app/graphql/queries/`
- Main schema in `photonia_schema.rb`
- Use field-level authorization with policies

## Testing Guidelines

### Ruby Tests (RSpec)

- Unit tests for models in `spec/models/`
- Controller tests focus on authentication and authorization
- Service tests in `spec/services/` for business logic
- Request tests in `spec/requests/` for GraphQL endpoints
- Job tests in `spec/jobs/` for background processing
- Policy tests in `spec/policies/` for authorization
- Factory definitions in `spec/factories/`
- System tests are currently disabled (see `.rspec`)

### JavaScript Tests (Vitest)

- Component tests in `app/javascript/test/`
- Use Vue Test Utils for component testing
- Test configuration in `vite.config.js`
- Mock external API calls
- Run with `npm run test:run`

## Database Considerations

- Uses PostgreSQL with `pg_search` for full-text search
- Tracks changes with `paper_trail` gem
- Uses `friendly_id` for SEO-friendly URLs
- Implements soft deletes where appropriate

## Security

- JWT-based authentication
- Pundit for authorization policies
- CORS configured for API access
- File uploads validated and processed securely
- Environment variables for sensitive configuration

## Deployment

- Dockerized application (see `Dockerfile`)
- Uses Kamal for deployment orchestration (see `.kamal/` directory)
- Production assets precompiled with Vite
- Supports horizontal scaling with Redis and PostgreSQL
- Health checks and monitoring with Sentry
- Multi-stage Docker build for optimized image size
- Runs as non-root user for security (rails:rails, UID 1000)

### Docker Setup

```bash
# Build production image
docker build -t photonia .

# Run with required environment variables
docker run -d -p 3000:3000 \
  -e RAILS_MASTER_KEY=<your_key> \
  -e DATABASE_URL=<postgres_url> \
  -e REDIS_URL=<redis_url> \
  photonia
```

### Kamal Deployment

- Configuration in `.kamal/deploy.yml`
- Hooks in `.kamal/hooks/` for deployment lifecycle
- Supports zero-downtime deployments
- Automatic SSL with Let's Encrypt support

## Performance Considerations

- Image thumbnails generated asynchronously
- Background jobs for heavy processing (Rekognition)
- Redis caching for frequently accessed data
- Database indexing for search performance
- CDN serving for static assets through S3

## Important Configuration Files

- `config/database.yml` - Database configuration
- `config/storage.yml` - File storage configuration (S3)
- `config/credentials/` - Encrypted credentials for each environment
- `vite.config.js` - Frontend build configuration
- `.env` files - Environment-specific variables
- `config/initializers/` - Rails initializers
- `.kamal/deploy.yml` - Deployment configuration
- `Procfile.dev` - Development process configuration

## Environment Variables

### Required for Production

- `RAILS_MASTER_KEY` - Rails encrypted credentials key
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `PHOTONIA_BE_SENTRY_DSN` - Sentry error reporting DSN

### AWS Configuration

- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region for S3 and Rekognition
- `AWS_S3_BUCKET` - S3 bucket name for photo storage

### Optional Configuration

- `PHOTONIA_BE_SENTRY_SAMPLE_RATE` - Sentry sampling rate (default: 0.1)
- `DOCKER_BUILD` - Set to 'true' during Docker build process

## External API Integration

### AWS Services

- S3 for photo storage with proper IAM permissions
- Rekognition for automated photo analysis and labeling
- Proper error handling for service unavailability

### Monitoring

- Sentry integration for error tracking
- Custom metrics for photo processing performance

## Common Development Tasks

### Adding New Photo Features

1. Update Photo model if needed
2. Add GraphQL mutations/queries
3. Implement background jobs for processing
4. Update Vue.js components
5. Add appropriate tests

### Adding New UI Components

1. Create Vue component in appropriate directory
2. Add to router if it's a page
3. Update state management if needed
4. Follow Vue.js composition API patterns
5. Write component tests

### Database Changes

1. Generate Rails migration
2. Update model associations
3. Add appropriate indexes
4. Update GraphQL schema
5. Write migration tests

## License and Contributing

This project is licensed under the Apache License 2.0. When contributing:

- Follow the existing code style and conventions
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting changes
- Use meaningful commit messages
- Consider the impact on existing users and backward compatibility

## Additional Resources

- **GitHub Repository**: https://github.com/photonia-io/photonia
- **Ruby on Rails Guides**: https://guides.rubyonrails.org/
- **Vue.js Documentation**: https://vuejs.org/guide/
- **GraphQL Specification**: https://graphql.org/learn/
- **AWS S3 Documentation**: https://docs.aws.amazon.com/s3/
- **AWS Rekognition Documentation**: https://docs.aws.amazon.com/rekognition/

Remember to always test changes locally before deploying and ensure both Ruby and JavaScript test suites pass.

## Model Overview

See the detailed data model documentation in `.kilocode/rules/data-models.md` for comprehensive information on the core models, their relationships, and behaviors within Photonia.
