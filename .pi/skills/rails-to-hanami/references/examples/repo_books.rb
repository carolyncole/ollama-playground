# app/repos/books.rb
#
# Rails:
#   Book.all
#   Book.find(params.expect(:id))
#   b = Book.new(book_params); b.save
#   b.update(book_params)
#   b.destroy!
#
# Hanami: explicit queries + CRUD, returns Dry::Monads::Result.
# Timestamps are set by hand (ROM has no save callbacks).

class Books < Repo
  include Dry::Monads[:result]

  def all
    rom.relations[:books]
  end

  def get(id:)
    case (record = rom.relations[:books].where(id: id).one)
    when nil
      Failure(BookNotFound.new(id: id))
    else
      Success(Structs::Book.new(record))
    end
  end

  def create(args)
    now = Time.now
    rom.commands(:sql).Insert.from(:books).call(
      title: args[:title], author: args[:author],
      created_at: now, updated_at: now,
    )
    # rom returns an id; re-read to return a struct via Result
    get(id: args[:id] || last_insert_id)
  end

  def update(id:, args)
    rom.commands(:sql).Update.from(:books).where(id: id).call(
      title: args[:title], author: args[:author], updated_at: Time.now,
    )
    get(id: id)
  end

  def delete(id:)
    Success(rom.commands(:sql).Update.from(:books).where(id: id).call)
  end
end

# ---- Encryption variant (orcid Token/User, replaces `encrypts :token`) ----
# class Users < Repo
#   def get(id:)
#     record = rom.relations[:users].where(id: id).one
#     record[:token] = deps.encryption.decrypt_openssl_token(record[:token])
#     Success(Structs::User.new(record))
#   end
#   def create(args)
#     rom.commands(:sql).Insert.from(:users).call(
#        **args, token: deps.encryption.encrypt_openssl_token(args[:token]))
#   end
# end
