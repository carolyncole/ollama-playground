# auto_register: false
# frozen_string_literal: true

require "hanami/action"
require "dry/monads"

module Bookshelf
  # App-wide base class for HTTP actions. No actions exist yet for this
  # app (the Rails port so far only covers the model/persistence layer) —
  # subclass this under `app/actions/<resource>/<verb>.rb` when porting
  # controllers.
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]
  end
end
