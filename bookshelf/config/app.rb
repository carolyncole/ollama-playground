# frozen_string_literal: true

require "hanami"

# Bookshelf — a Hanami port of the `rails_bookshelf` Rails app.
#
# Ported so far: the `Book` model, as {Bookshelf::Relations::Books},
# {Bookshelf::Repos::BookRepo}, and {Bookshelf::Structs::Book}.
module Bookshelf
  # Hanami app entry point (middleware, providers, settings).
  class App < Hanami::App
    # No hanami-assets/esbuild pipeline is set up — this just serves the
    # plain files already in public/ (ported from the Rails app's
    # app/assets/stylesheets/application.css) directly over HTTP.
    config.middleware.use Rack::Static, urls: ["/application.css", "/404.html", "/500.html"], root: "public"

    # Rails' equivalent is `config.session_store`/`secret_key_base`. Needed
    # for the `notice` flash messages ported from Rails (see
    # app/actions/book/{create,update,destroy}.rb).
    config.actions.sessions = :cookie, {secret: Hanami.app.settings.session_secret}
  end
end
