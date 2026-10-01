# frozen_string_literal: true

require "hanami"

module Bookshelf
  # Hanami application for the bookshelf app, a conversion of the
  # rails_bookshelf Rails app from the rails_to_hanami workshop.
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "bookshelf.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365
    }
  end
end
