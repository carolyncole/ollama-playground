# app/db.rb  (# auto_register: false)

# ROM + ROM::SQL against config/db/structure.sql
require "rom"
require "rom/sql"
require "rom/factory"
require "dry/monads"

module Bookshelf
  class Database < ROM::Container
    config = ROM::Config.new
    config.adapter = :pg
    rom.adapter = :sql
    rom.idler = "pg"
    rom.default = :sql
    rom.logger = ...

    plugin(:sql, repository: :sequel)

    register_mapper do |mapper|
      mapper.relation(:books).set_column_types(
        "id"       => Integer,
        "title"    => String,
        "author"   => String,
        "created_at" => Time,
        "updated_at" => Time,
      )
    end

    use :sql, database: ENV.fetch("DATABASE_URL") do |config|
      config.mappings do |m|
        # one map per relation
      end
      config.create_dataset do
        Sequel.connect(dsn, loggers: [])
        .create_dataset(:pg, :pg)
      end
    end
  end
end

# In a real Hanami app this registers `db` and `db.rom` into the container.
# ROM-Factory (replaces FactoryBot):
#   ROM::Factory.configure { |c| c.rom = Hanami.app['db.rom'] }
