# auto_register: false
# frozen_string_literal: true

require "hanami/view"

module Bookshelf
  # App-wide base class for views (presenters), subclassed under
  # `app/views/<resource>/<action>.rb`. Templates live alongside, under
  # `app/templates/<resource>/<action>.html.erb`.
  class View < Hanami::View
  end
end
