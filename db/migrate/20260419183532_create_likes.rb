class CreateLikes < ActiveRecord::Migration[7.0]
  def change
    create_table :likes do |t|
      t.integer :user_id, null: false
      t.integer :blog_id, null: false
      t.timestamps
    end

    # ✅ Same user same blog ko dobara like na kar sake
    add_index :likes, [:user_id, :blog_id], unique: true
  end
end