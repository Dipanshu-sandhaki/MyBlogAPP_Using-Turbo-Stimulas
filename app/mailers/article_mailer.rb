class ArticleMailer < ApplicationMailer
  default from: ENV["GMAIL_USERNAME"]

  def send_article_notification(recipient_email, blog)
    @recipient_email = recipient_email
    @blog = blog
    @recipient_name = recipient_email.split("@").first

    mail(
      to: recipient_email,
      subject: "Check out this article: #{@blog.title}"
    )
  end
end