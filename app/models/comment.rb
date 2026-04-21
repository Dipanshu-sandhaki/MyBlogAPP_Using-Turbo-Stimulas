class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :blog

  validates :body, presence: true, length: { minimum: 1, maximum: 500 }
end