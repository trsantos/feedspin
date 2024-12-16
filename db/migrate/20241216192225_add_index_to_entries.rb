class AddIndexToEntries < ActiveRecord::Migration[7.2]
  def change
    add_index :entries, %i[feed_id fj_entry_id], unique: true
    remove_index :entries, name: :index_entries_on_fj_entry_id_and_url
  end
end
