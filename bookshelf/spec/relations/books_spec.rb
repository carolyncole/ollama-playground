# frozen_string_literal: true

RSpec.describe Bookshelf::Relations::Books, :db do
  subject(:relation) { Hanami.app["relations.books"] }

  it "reads an empty books table" do
    expect(relation.to_a).to eq([])
  end

  it "reads rows inserted directly into the books table" do
    relation.insert(
      title: "Design Patterns",
      author: "Gang of Four",
      created_at: Time.now,
      updated_at: Time.now
    )

    expect(relation.to_a.map { |row| row[:title] }).to eq(["Design Patterns"])
  end
end
