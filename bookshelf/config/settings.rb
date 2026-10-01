# frozen_string_literal: true

module Bookshelf
  class Settings < Hanami::Settings
    # Used to sign the session cookie (flash messages). Rails' equivalent is
    # `secret_key_base`/`Rails.application.credentials`. Fine as a committed
    # dev default for this app; override via the `SESSION_SECRET` env var
    # for any real deployment.
    setting :session_secret,
            default: "bookshelf_dev_session_secret_at_least_64_bytes_long_1234567890abcdef",
            constructor: Types::String
  end
end
