class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  has_many :blogs, dependent: :destroy
  has_many :active_follows, class_name: "Follow",
           foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "Follow",
           foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower
  has_many :likes, dependent: :destroy
  has_many :liked_blogs, through: :likes, source: :blog
  has_many :comments, dependent: :destroy

  enum :role, { viewer: 0, writer: 1, admin: 2 }, default: :viewer

  def following?(other_user)
    following.include?(other_user)
  end

  def follow!(other_user)
    active_follows.create!(followed: other_user)
  end

  def unfollow!(other_user)
    active_follows.find_by(followed: other_user)&.destroy
  end

  def liked?(blog)
    likes.exists?(blog: blog)
  end

  def avatar_url
    avatar.attached? ? avatar : nil
  end
end