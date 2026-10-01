# frozen_string_literal: true

# Ported near-verbatim from the Rails app's spec/system/book_delete_spec.rb
# (type: :system -> type: :feature, ActiveRecord -> BookRepo; `change(Book,
# :count)` -> `change { repo.all.count }`).
RSpec.describe "books/new", type: :feature do
  it "visits the book show page and destroys the book" do
    repo = Bookshelf::Repos::BookRepo.new
    book = repo.create(title: "book 1", author: "author 1")
    visit "/books/#{book.id}"

    expect(page).to have_content "Title: book 1"
    expect(page).to have_content "Author: author 1"

    expect { click_on "Destroy this book" }.to change { repo.all.count }.by(-1)
    expect(page).to have_content("Book was successfully destroyed")
    expect(page).to have_content "Welcome to the Bookshelf"
  end
end
