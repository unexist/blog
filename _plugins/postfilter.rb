module Jekyll
  module PostFilter
    def to_post_url(url)
        post_url url
    end
  end
end

Liquid::Template.register_filter(Jekyll::PostFilter)