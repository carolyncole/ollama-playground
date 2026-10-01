# frozen_string_literal: true

require "dry/types"

module Bookshelf
  Types = Dry.Types(default: :strict)

  # Dry::Types container (`Dry.Types(default: :strict)`), extended here for
  # any app-specific custom types.
  module Types
    # Define your custom types here
  end
end
