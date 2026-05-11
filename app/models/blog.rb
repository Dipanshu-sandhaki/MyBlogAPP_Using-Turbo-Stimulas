class Blog < ApplicationRecord
  belongs_to :user

  has_rich_text :content
  has_one_attached :cover_image

  has_many :likes, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user
  has_many :comments, dependent: :destroy

  enum :status, { draft: "draft", saved: "saved", published: "published" }, default: "draft"

  # Title & content only required when saving or publishing — not for drafts
  validates :title, presence: true, unless: :draft?
  validates :content, presence: true, unless: :draft?
end