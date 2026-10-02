# app/actions/books/create.rb
#
# Rails:
#   def create
#     @book = Book.new(book_params)
#     if @book.save
#       redirect_to @book, notice: "Book was successfully created."
#     else
#       render :new, status: :unprocessable_entity
#     end
#   end
#   def book_params; params.expect(book: [:title, :author]); end

class Create < Action
  params do
    required(:title).filled?(String)
    optional(:author).filled?(String).default("")
  end
  def call(request, response)
    case (result = deps.books_repo.create(params))
    in Success(book)
      response.redirect_to(
         routes.book(id: book.id),
        flash: { notice: "Book was successfully created." },
      )
    in Failure(error)
      response.status = :unprocessable_entity
      response.render(
         Books::Views::New,
         book: result,
         current_user: response[:current_user],
      )
    end
  end
end
