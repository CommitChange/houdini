require "./lib/qx"

require "minitest/autorun"

# Qx.quote escapes through the database adapter, so parse needs a connection
ActiveRecord::Base.establish_connection("postgres://admin:password@localhost/qx_test")
class UpsertTest < Minitest::Test
  def setup
  end

  def test_upsert
    table = "x"
    column1 = "a"
    column2 = "b"
    idx = "idx_something_more"

    result = Qx.insert_into(table).values({column1: column1, column2: column2}).on_conflict.upsert(idx).parse

    expected = %(INSERT INTO "#{table}" ("column1", "column2") VALUES ('#{column1}', '#{column2}') ON CONFLICT ON CONSTRAINT #{idx} DO UPDATE SET "column1" = EXCLUDED."column1", "column2" = EXCLUDED."column2")
    assert_equal(expected, result)
  end
end
