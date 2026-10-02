# app/actions/books/index.rb
#
# Rails:
#   def index; @books = Book.all; end

class Index < Action
  def call(request, response)
    books = deps.books_repo.all
    response.render(
      Books::Views::Index,
       books: books,
       current_user: response[:current_user],
     )
  end
end

# current_user (if present) is set on response by a base Action:
#
# class Action < Hanami::Action
#   def before
#     case (user = deps.auth.current_user)
#     in Success(u) ; response[:current_user] = u; true
#     else false; end  # or redirect to sessions_new
#   end
# end
