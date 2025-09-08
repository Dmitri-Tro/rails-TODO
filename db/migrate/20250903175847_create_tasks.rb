class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'pending'
      t.references :user, null: false, foreign_key: true
      # Убираем category_id - добавим позже
      t.datetime :due_date
      t.integer :priority, default: 0

      t.timestamps
    end
    
    add_index :tasks, :status
    add_index :tasks, :due_date
  end
end
