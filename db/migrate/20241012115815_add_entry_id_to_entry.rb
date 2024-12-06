class AddEntryIdToEntry < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :fj_entry_id, :string
    add_index :entries, :fj_entry_id, unique: true
  end
end
