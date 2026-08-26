# list pulled from redit https://www.reddit.com/r/ruby/comments/16zu7vy/good_books/
["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
    Book.find_or_create_by!(title: "99 Bottles of OOP", author: "Sandi Metz")
    Book.find_or_create_by!(title: "Design Patterns", author: "Gang of Four")
    Book.find_or_create_by!(title: "Practical Object-Oriented Design", author: "Sandi Metz")
end