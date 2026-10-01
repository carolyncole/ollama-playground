json.extract! book, :id, :author, :title, :created_at, :updated_at
json.url book_url(book, format: :json)
