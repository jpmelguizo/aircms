require 'redcarpet'

activate :relative_assets
set :relative_links, true
activate :directory_indexes

set :css_dir, 'css'
set :layout, 'html'
set :build_dir, 'docs'

set :markdown_engine, :redcarpet

page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

helpers do

  # creates link with active class in case its href is the current url
  def menu_link(link_text, url, options = {})
    # github pages fix
    if environment == :development
      site_url = ""
    else
      site_url = "/aircms"
    end
    if current_resource.url === "#{url}/" || current_resource.url === "#{url}"
      if options[:class]
        options[:class] << ' active'
      else
        options[:class] = 'active'
      end
    end
    link_to(link_text, "#{site_url}#{url}", options)
  end

  def md(text)
    markdown = Redcarpet::Markdown.new Redcarpet::Render::HTML
    markdown.render(text)
  end

  # Render single image from airtable source
  def single_img(source, index = 0, options = {})
    image_tag(source[index]['url'], options)
  end

  # get resources from sitemap
  def sitemapResources(resourceType)
    sitemap.resources.select{|r| r.content_type === resourceType}
  end

  # get html (pages that are rendered) from sitemap
  def htmlResources()
    sitemapResources('text/html; charset=utf-8')
  end

  # get pages by type
  def getPagesByType(pageType)
    htmlResources.select {|r| r.locals[:tipo] === pageType }
  end

  # get page (html resource) given an Airtable id
  def getPage(id)
    htmlResources.select {|r| r.locals[:id] === id }[0]
  end

  # article list of links
  def articleLinks
    # github pages
    if environment == :development
      site_url = ""
    else
      site_url = "/aircms"
    end
    links = []
    articles = getPagesByType('articulo').sort_by {|r| r.locals[:fecha]}
    articles.each do |article|
      title = article.locals[:titulo]
      link = link_to(title, "#{site_url}/blog/#{title.parameterize}")
      links.push(link)
    end
    links
  end
end

###
# Airtable dynamic pages with Middleman
###

# Connects to Airtable, get your token at: https://airtable.com/account
@client = Airtable::Client.new(@app.data.airtable.apikey)
# Selects the table, see: https://airtable.com/api
@pages = @client.table(@app.data.airtable.baseid, 'paginas')
# Gets records, see more options at: https://github.com/Airtable/airtable-ruby
@pagesRecords = @pages.records.select {|r| r.publico == true }
# Creates a dynamic page for each record
@pagesRecords.each do |page|
  fields = {}
  # Gets all airtable fields
  page.fields.each do |fieldKey, fieldValue|
    fields[fieldKey.parameterize.underscore.to_sym] = fieldValue
  end
  fields[:tipo] = 'pagina'
  # Creates pages for every record
  # Defines /airtable.html.erb as template for them
  # Adds fields as local variables usable and renderable in the template
  proxy "/#{fields[:ruta]}.html", "/paginas.html",
    :locals => fields,
    # Tells Middleman not to create a page for /airtable.html.erb itself
    :ignore => true
end

# get articles
@articles = @client.table(@app.data.airtable.baseid, "articulos")
@articlesRecords = @articles.records(:sort => ["fecha", :asc]).select {|r| r.publico == true }
@articlesRecords.each do |article|
  fields = {}
  article.fields.each do |fieldKey, fieldValue|
    fields[fieldKey.parameterize.underscore.to_sym] = fieldValue
  end
  fields[:tipo] = 'articulo'
  proxy "/blog/#{fields[:titulo].parameterize}.html", "/blog/articulos.html",
    :locals => fields,
    :ignore => true
end
