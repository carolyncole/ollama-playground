# frozen_string_literal: true

RSpec.describe Bookshelf::Structs::Book, :db do
  subject(:book) do
    Bookshelf::Repos::BookRepo.new.create(title: "Hanami in Action", author: "Sean Collins")
  end

  it "exposes the persisted attributes as readers" do
    expect(book.id).to be_a(Integer)
    expect(book.title).to eq("Hanami in Action")
    expect(book.author).to eq("Sean Collins")
    expect(book.created_at).to be_a(Time)
    expect(book.updated_at).to be_a(Time)
  end

  it "is immutable — there are no attribute writers" do
    expect(book).not_to respond_to(:title=)
    expect(book).not_to respond_to(:author=)
  end
end
