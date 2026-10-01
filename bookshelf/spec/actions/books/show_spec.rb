# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::Show, :db do
  subject(:action) { described_class.new }

  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "99 Bottles of OOP", author: "Sandi Metz") }

  it "renders the book" do
    response = action.call(id: book.id.to_s)

    expect(response.status).to eq(200)
    expect(response.body.join).to include("99 Bottles of OOP").and include("Sandi Metz")
  end

  it "raises when no book matches the id" do
    expect { action.call(id: "-1") }.to raise_error(ROM::TupleCountMismatchError)
  end
end
