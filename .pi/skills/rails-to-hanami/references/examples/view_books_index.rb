# app/views/books/index.rb
#
# Rails used app/views/books/index.html.erb + _book.html.erb partial.
# Hanami: one View per action; `expose :x` declares what the template may read.
# current_user comes from the layout (set by the base Action before hook).

module Books
  module Views
    class Index < View
      expose :routes
      expose :current_user, layout: true
      expose :books
    end
  end
end

# JSON variant (orcid-style, no layout):
# base View#call(format:) passes layout: nil when format: :json;
# a .jbuilder template renders Jbuilder via Tilt.
#
# class Index < View
#   expose :routes
#   expose :books
# end
# # template: app/templates/books/index.jbuilder
