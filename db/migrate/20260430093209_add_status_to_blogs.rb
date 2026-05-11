class AddStatusToBlogs < ActiveRecord::Migration[7.1]
  def change
    add_column :blogs, :status, :string, default: "draft", null: false
  end
end