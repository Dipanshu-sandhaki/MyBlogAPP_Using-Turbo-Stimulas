# Be sure to restart your server when you modify this file.

Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.paths << Rails.root.join("app/javascript")

Rails.application.config.assets.precompile += %w[
  application.js
  application.css
  controllers/application.js
  controllers/index.js
  controllers/bulk_select_controller.js
  controllers/bulk_upload_controller.js
  controllers/blog_editor_controller.js
  controllers/comment_edit_controller.js
  controllers/darkmode_controller.js
  controllers/dropdown_controller.js
  controllers/flash_controller.js
  controllers/form_controller.js
  controllers/hello_controller.js
  controllers/modal_controller.js
  controllers/read_more_controller.js
]