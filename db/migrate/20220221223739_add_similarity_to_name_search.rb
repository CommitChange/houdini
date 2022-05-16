class AddSimilarityToNameSearch < ActiveRecord::Migration
  def up
    enable_extension :pg_trgm
    enable_extension :btree_gin

    execute <<-SQL
      CREATE INDEX name_search_idx
      ON supporters
      USING gin (name gin_trgm_ops);
    SQL
  end

  def down
    remove_index :supporters, name: :name_search_idx
  end
end
