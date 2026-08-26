require 'rails_helper'

RSpec.describe "books/index", type: :view do
  before(:each) do
    assign(:books, [
      Book.create!(
        title: "Title",
        author: "Author"
      ),
      Book.create!(
        title: "Title",
        author: "Author"
      )
    ])
  end

  it "renders a list of books" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Author".to_s), count: 2
  end
end
