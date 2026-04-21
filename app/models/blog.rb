class Blog < ApplicationRecord
  belongs_to :user

    has_rich_text :content 
    has_one_attached :cover_image

  has_many :likes, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true
end