# frozen_string_literal: true

module Bookshelf
  module Views
    module Books
      # View for {Bookshelf::Actions::Books::New}, also reused by
      # {Bookshelf::Actions::Books::Create} to re-render the form on failure.
      #
      # Exposes the same `form_submit`/`form_method`/`form_path`/`book` locals as
      # {Bookshelf::Views::Books::Edit} so both views can share `_form.html.erb`.
      class New < Bookshelf::View
        include Deps["repos.book_repo"]

        # @!method form_submit
        #   @return [String] the form's submit button label
        expose :form_submit, default: "Create Book"

        # @!method form_method
        #   @return [String] the HTTP method the form submits with
        expose :form_method, default: "POST"

        # @!method form_path
        #   @return [String] the path the form submits to
        expose :form_path do |context:|
          context.routes.path(:books)
        end

        # @!method book
        #   @return [Hash, nil] the submitted `book` params, re-populating the form after a
        #     failed create
        expose :book do |context:|
          context.request.params[:book]
        end
      end
    end
  end
end
