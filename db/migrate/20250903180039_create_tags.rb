class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.string :color, default: '#6c757d'
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tags, [:user_id, :name], unique: true
  end
end
