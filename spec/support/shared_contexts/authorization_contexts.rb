# frozen_string_literal: true

# Shared context for authorization specs to provide common actors
# Usage:
#   include_context 'with auth actors'
RSpec.shared_context 'with auth actors', shared_context: :metadata do
  let(:owner)    { create(:user) }
  let(:stranger) { create(:user) }
  let(:admin)    { create(:user, admin: true) }
end
