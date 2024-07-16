class AddUniqueIndexForCards < ActiveRecord::Migration[7.0]
  def change
    add_index :cards, [:user_id, :shop_id], unique: true
  end
end
