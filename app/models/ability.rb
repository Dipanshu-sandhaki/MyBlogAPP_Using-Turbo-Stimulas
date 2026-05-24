# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    role = user.role || "viewer"

    case role
    when "admin"
      can :manage, :all

    when "writer"
      can :read,        Blog, status: "published"
      can :read,        Blog, user_id: user.id
      can :create,      Blog
      can :update,      Blog, user_id: user.id
      can :destroy,     Blog, user_id: user.id
      can :bulk_upload, Blog
      can :bulk_create, Blog
      can :bulk_delete, Blog
      can :share_email, Blog

      can :create,  Comment
      can :update,  Comment, user_id: user.id
      can :destroy, Comment, user_id: user.id

      can :create,  Like
      can :destroy, Like

    when "viewer"
      can :read,        Blog,    status: "published"
      can :read,        Comment
      can :share_email, Blog       

      can :create,  Comment        
      can :update,  Comment, user_id: user.id  
      can :destroy, Comment, user_id: user.id  

      can :create,  Like           
      can :destroy, Like            
    end
  end
end