class AddAudioToEntry < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :audio, :string
  end
end
