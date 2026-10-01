# frozen_string_literal: true

module Bookshelf
  class Settings < Hanami::Settings
    setting :session_secret, constructor: Types::String,
      default: "____local_development_secret_only____local_development_secret_only___"
  end
end
