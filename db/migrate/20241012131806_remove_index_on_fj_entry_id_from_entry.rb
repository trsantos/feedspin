class RemoveIndexOnFjEntryIdFromEntry < ActiveRecord::Migration[7.2]
  def change
    remove_index :entries, :fj_entry_id
    add_index :entries, %i[fj_entry_id url]
  end
end
