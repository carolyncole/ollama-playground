# app/structs/book.rb
#
# Immutable record + any old model instance methods.
# No persistence here — that is the Repo's job.
# No encryption helpers here — those live in the Repo.

class Book < Struct
  attributes :id, :title, :author, :created_at, :updated_at

  # Example of migrated instance methods:
  # def to_s; title; end
  # def full_citation; "#{author}, #{title}"; end
end
