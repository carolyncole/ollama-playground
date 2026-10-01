# frozen_string_literal: true

module Bookshelf
  module Views
    module Books
      class New < Bookshelf::View
        include Deps["repos.book_repo"]

        expose :form_submit, default: "Create Book"
        expose :form_method, default: "POST"
        expose :form_path do |context:|
          context.routes.path(:books)
        end
        expose :book do |context:|
          context.request.params[:book]
        end
      end
    end
  end
end
