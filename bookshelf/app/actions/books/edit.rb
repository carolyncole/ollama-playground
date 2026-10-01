# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      class Edit < Bookshelf::Action
        params do
          required(:id).filled(:integer)
        end

        def handle(request, response)
        end
      end
    end
  end
end
