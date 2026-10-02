# app/actions/books/show.rb
#
# Rails:
#   before_action :set_book, only: %i[show edit update destroy]
#   def set_book; @book = Book.find(params.expect(:id)); end
#   def show; end
#
# The before-action guard becomes an explicit repo call with failure handling;
# "not found" redirects/errors the way ActiveRecord's `find` raised RecordNotFound.

class Show < Action
  params do
    required(:id).filled?(Integer)
  end
  def call(request, response)
    case (result = deps.books_repo.get(id: params[:id]))
    in Success(book)
      response.render(
         Books::Views::Show,
         book: book,
         current_user: response[:current_user],
      )
    in Failure(:book_not_found)
      response.status = :not_found
      response.redirect_to(routes.books_index,
        flash: { alert: "Book not found." })
    end
  end
end
