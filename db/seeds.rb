Feed.update_all top_site: false

def insert_top_sites(urls)
  urls.each do |url|
    Feed.find_or_create_by(feed_url: url).update_attribute(:top_site, true)
  end
end

top_sites = [
  'https://feeds.bloomberg.com/technology/news.rss',
  'https://www.theverge.com/rss/full.xml',
  'https://techcrunch.com/feed/',
  'https://feeds.a.dj.com/rss/RSSWSJD.xml',
  'https://www.nytimes.com/svc/collections/v1/publish/https://www.nytimes.com/section/technology/rss.xml',
  'https://www.wired.com/feed/rss',
  'https://www.404media.co/rss/',
  # 'https://www.theinformation.com/feed',
  'https://www.ft.com/rss/home',
  'http://feeds.arstechnica.com/arstechnica/index',
  'https://www.cnbc.com/id/19854910/device/rss/rss.html'
]

insert_top_sites top_sites
