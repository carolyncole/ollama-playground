# frozen_string_literal: true

module Bookshelf
  class Routes < Hanami::Routes
    resources :books
  end
end
