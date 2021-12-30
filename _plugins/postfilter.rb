module Jekyll
  module PostFilter
    def to_post_link(url)
        post_url url
    end
  end
end

Liquid::Template.register_filter(Jekyll::PostFilter)