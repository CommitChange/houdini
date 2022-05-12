class AddSimilarityToNameSearch < ActiveRecord::Migration
  def change
    enable_extension :pg_trgm
    enable_extension :btree_gin

    add_index :supporters, :name, name: :name_search_idx, using: :gin, order: {name: :gin_trgm_ops}
  end
end
