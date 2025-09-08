class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.text :description
      t.string :color, default: '#007bff'
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :categories, [:user_id, :name], unique: true
  end
end
