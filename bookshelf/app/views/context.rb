# auto_register: false
# frozen_string_literal: true

module Bookshelf
  # View classes (presenters, one per action) and their templates/partials,
  # context, and helpers.
  module Views
    # App-wide view context, shared by every template/partial/layout.
    # Already provides `content_for`, `flash`, `routes`, `session`, and
    # `csrf_token` (see `Hanami::View::Context`) — {Bookshelf::Views::Helpers}
    # is mixed in automatically by convention.
    class Context < Hanami::View::Context
    end
  end
end
