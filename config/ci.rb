# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Tests: Ruby", "bundle exec rspec"
  step "Tests: JS", "yarn test:run"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
end
