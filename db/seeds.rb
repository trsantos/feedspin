Feed.update_all top_site: false

def insert_top_sites(urls)
  urls.each do |url|
    Feed.find_or_create_by(feed_url: url).update_attribute(:top_site, true)
  end
end

top_sites = [
  'https://news.ycombinator.com/rss',
  'https://lobste.rs/rss',
  'https://feeds.bloomberg.com/technology/news.rss',
  'https://www.theverge.com/rss/full.xml',
  'https://techcrunch.com/feed/',
  'https://www.nytimes.com/svc/collections/v1/publish/https://www.nytimes.com/section/technology/rss.xml',
  'https://feeds.a.dj.com/rss/RSSWSJD.xml',
  'https://www.wired.com/feed/rss',
  'https://www.404media.co/rss/',
  'https://www.theinformation.com/feed',
  'http://feeds.arstechnica.com/arstechnica/index',
  'https://www.cnbc.com/id/19854910/device/rss/rss.html',
  'https://www.bleepingcomputer.com/feed/',
  'https://www.androidauthority.com/feed/',
  'https://9to5mac.com/feed/',
  'https://9to5google.com/feed/',
  'https://krebsonsecurity.com/feed/',
  'https://rss.politico.com/technology.xml',
  'https://www.windowscentral.com/rss.xml',
  'https://www.tomshardware.com/feeds.xml',
  'https://feeds.macrumors.com/MacRumors-All',
  'https://www.platformer.news/rss/',
  'https://feeds.bbci.co.uk/news/technology/rss.xml',
  'https://appleinsider.com/rss/news',
  'https://www.theregister.com/headlines.atom'
]

insert_top_sites top_sites
