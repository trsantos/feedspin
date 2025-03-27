class AddHasTextToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :has_text, :boolean, default: true
  end
end
