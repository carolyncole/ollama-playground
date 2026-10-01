# frozen_string_literal: true

# Ported near-verbatim from the Rails app's spec/system/book_edit_spec.rb
# (type: :system -> type: :feature, ActiveRecord -> BookRepo; `book.reload`
# -> re-fetch via BookRepo#get, since structs are immutable).
RSpec.describe "book/", type: :feature do
  it "visits the book show page and edits the book" do
    repo = Bookshelf::Repos::BookRepo.new
    book = repo.create(title: "book 1", author: "author 1")
    repo.create(title: "book 2", author: "author 2")
    visit "/books/#{book.id}"

    expect(page).to have_content "Title: book 1"
    expect(page).not_to have_content "Title: book 2"
    expect(page).to have_content "Author: author 1"
    expect(page).not_to have_content "Author: author 2"
    click_on "Edit this book"
    expect(find("#book_title").value).to eq("book 1")
    expect(find("#book_author").value).to eq("author 1")
    fill_in "book_title", with: "book 1 update"
    click_on "Update Book"

    book = repo.get(book.id)
    expect(book.title).to eq("book 1 update")
  end
end
