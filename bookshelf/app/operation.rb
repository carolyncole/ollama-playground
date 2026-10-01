# auto_register: false
# frozen_string_literal: true

require "dry/operation"

module Bookshelf
  # App-wide base class for fallible business logic (`Success`/`Failure`
  # via `step`), subclassed under `app/operations/*.rb`. Not used yet by
  # this app — the Book model has no behavior that can fail.
  class Operation < Dry::Operation
  end
end
