# frozen_string_literal: true

# Ported near-verbatim from the Rails app's spec/system/book_show_spec.rb
# (type: :system -> type: :feature, ActiveRecord -> BookRepo).
RSpec.describe "book/", type: :feature do
  it "visits the book show page" do
    repo = Bookshelf::Repos::BookRepo.new
    book = repo.create(title: "book 1", author: "author 1")
    repo.create(title: "book 2", author: "author 2")
    visit "/books/#{book.id}"

    expect(page).to have_content "Title: book 1"
    expect(page).not_to have_content "Title: book 2"
    expect(page).to have_content "Author: author 1"
    expect(page).not_to have_content "Author: author 2"
  end
end
