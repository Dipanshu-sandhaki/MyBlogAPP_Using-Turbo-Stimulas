Rails.application.config.to_prepare do
  require "loofah"

  allowed_tags = begin
    Loofah::HTML5::SafeListProtocol::ALLOWED_TAGS
  rescue NameError
    begin
      Loofah::HTML5::SafeList::ALLOWED_TAGS
    rescue NameError
      nil
    end
  end

  allowed_attrs = begin
    Loofah::HTML5::SafeListProtocol::ALLOWED_ATTRIBUTES
  rescue NameError
    begin
      Loofah::HTML5::SafeList::ALLOWED_ATTRIBUTES
    rescue NameError
      nil
    end
  end

  if allowed_tags && allowed_attrs
    allowed_tags.add("span")
    allowed_attrs.add("style")
  end

  # Also patch ActionText directly as backup
  ActionText::ContentHelper.module_eval do
    def sanitize(source, options = {})
      options[:tags] = Array(options[:tags]) | %w[
        span div p br h1 h2 h3 h4 h5 h6
        strong em s del a ul ol li blockquote pre figure figcaption
        action-text-attachment
      ]
      options[:attributes] = Array(options[:attributes]) | %w[
        style class href id
        sgid content filename filesize
        data-trix-attachment data-trix-content-type
        data-trix-id data-trix-store-key data-trix-mutable
        data-trix-serialized-attributes
        caption presentation url width height
      ]
      super(source, options)
    end
  end
end