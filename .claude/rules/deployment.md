---
paths:
  - "config/deploy*.yml"
  - ".kamal/**"
  - "Dockerfile"
---

# Deployment

`kamal deploy -d production` (a destination is required).

- `config/deploy.yml` (tracked): shared non-secret config and `env.clear` values.
- `config/deploy.production.yml` (gitignored, real server IP/hostname): server, proxy, accessories. Copy from `config/deploy.production.template.yml`.
- Secrets: `.kamal/secrets.production` fetches from 1Password (`Credentials/Photonia`; registry password from `Credentials/General`). Needs the `op` CLI signed in and `$OP_ACCOUNT` exported.

**Publish a GitHub release after every deploy.** Tag `release-X.Y.Z`, title prefixed with the version (README "Versioning & Releases"). Start from `gh api repos/photonia-io/photonia/releases/generate-notes -f tag_name=release-X.Y.Z -f previous_tag_name=<last tag>`, reorganize, and match the title style of the last three releases (`gh release list --limit 3`, `gh release view <tag>`).
