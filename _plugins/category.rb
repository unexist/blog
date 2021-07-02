module Jekyll
    module Helpers
        def jekyll_category_slug(str)
            str.to_s.replace_diacritics.downcase.gsub(/\s/, '-')
        end
    end

    class CategoryGenerator < Generator
        include Helpers
        safe true
        attr_accessor :site
        @types = [:page, :feed]

        class << self; attr_accessor :types, :site; end

        def generate(site)
            self.class.site = self.site = site

            site.categories.each do |category, posts|
                new_category(category, posts)
            end
        end

        def new_category(category, posts)
            self.class.types.each do |type|
                if layout = site.config["category_#{type}_layout"]
                    data = { 'layout' => layout, 'posts' => posts.sort.reverse!, 'category' => category }
                    data.merge!(site.config["category_#{type}_data"] || {})

                    name = yield data if block_given?
                    name ||= category
                    name = jekyll_category_slug(name)

                    category_dir = site.config["category_#{type}_dir"]
                    category_dir = File.join(category_dir, (pretty? ? name : ''))

                    page_name = "#{pretty? ? 'index' : name}#{site.layouts[data['layout']].ext}"

                    site.pages << CategoryPage.new(
                        site, site.source, category_dir, page_name, data
                    )
                end
            end
        end
    end

    class CategoryPage < Page
        def initialize(site, base, dir, name, data = {})
            self.content = data.delete('content') || ''
            self.data    = data

            super(site, base, dir[-1, 1] == '/' ? dir : '/' + dir, name)
        end

        def read_yaml(*)
            # Do nothing
        end
    end
end