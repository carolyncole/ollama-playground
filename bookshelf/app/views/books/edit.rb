# frozen_string_literal: true

module Bookshelf
  module Views
    module Books
      # View for {Bookshelf::Actions::Books::Edit}, also reused by
      # {Bookshelf::Actions::Books::Update} to re-render the form on failure.
      #
      # Exposes the same `form_submit`/`form_method`/`form_path`/`book` locals as
      # {Bookshelf::Views::Books::New} so both views can share `_form.html.erb`.
      class Edit < Bookshelf::View
        include Deps["repos.book_repo"]

        # @!method form_submit
        #   @return [String] the form's submit button label
        expose :form_submit, default: "Update Book"

        # @!method form_method
        #   @return [String] the HTTP method the form submits with
        expose :form_method, default: "PATCH"

        # @!method form_path
        #   @return [String] the path the form submits to
        expose :form_path do |context:, id:|
          context.routes.path(:book, id: id)
        end

        # @!method book
        #   @return [Bookshelf::Structs::Book] the book matching the `id` route param
        #   @raise [ROM::TupleCountMismatchError] if no book matches `id`
        expose :book do |context:, id:|
          book_repo.get(id)
        end
      end
    end
  end
end
