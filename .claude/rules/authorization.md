---
paths:
  - "app/policies/**"
  - "app/models/user.rb"
  - "app/models/role.rb"
  - "config/initializers/devise.rb"
  - "app/graphql/types/mutation_type.rb"
  - "app/graphql/mutations/continue_with_*.rb"
  - "app/services/continue_with_facebook_service.rb"
  - "spec/policies/**"
---

# Authorization and auth

- Two live mechanisms: `users.admin` boolean, and `roles`/`roles_users` HABTM (`Role#symbol`). `User#has_role?(sym)` is true for any admin. Uploading needs `has_role?(:uploader)`.
- Policies deny by default (`ApplicationPolicy`). `PhotoPolicy::Scope` / `AlbumPolicy::Scope`: visitor sees public, user sees public + own, admin sees all.
- OAuth isn't OmniAuth: `Mutations::ContinueWithGoogle` verifies a Google One-Tap credential; `ContinueWithFacebookService` verifies Facebook's signed request. Both gated by `Setting` toggles.
- JWT dispatch/revocation matches the GraphQL operation name in the request body (`config/initializers/devise.rb`): `/signIn|continueWithGoogle|continueWithFacebook/` issues, `/signOut/` revokes. This needs the pinned `photonia-io/warden-jwt_auth` fork. Renaming those operations silently breaks auth.
