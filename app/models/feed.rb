class Feed < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper

  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  has_many :entries, dependent: :destroy
  
  validates :feed_url, presence: true, uniqueness: true

  def self.entries_per_feed
    return 5
  end

  def update
    feed = fetch_and_parse
    return if feed.is_a? Integer
    update_entries feed
  end

  def only_images?
    self.entries.each do |e|
      return false if !(e.image && e.description.blank?)
    end
    return true
  end

  private

  def fetch_and_parse
    setup_fj
    begin
      return Feedjira::Feed.fetch_and_parse self.feed_url
    rescue
    end
    return 0
  end

  def update_entries(feed)
    self.update_attributes(title: feed.title, site_url: process_url(feed.url || feed.feed_url))

    entries = feed.entries.first(Feed.entries_per_feed)

    if has_new_entries? entries
      self.entries.destroy_all
      entries.each { |e| insert_entry e }
      self.subscriptions.each { |s| s.update_attribute(:updated, true) }
    end
  end

  def has_new_entries?(entries)
    entries.each do |e|
      return true unless self.entries.find_by(url: e.url)
    end
    false
  end

  def setup_fj
    Feedjira::Feed.add_common_feed_entry_element("enclosure", :value => :url, :as => :image)
    Feedjira::Feed.add_common_feed_entry_element("media:thumbnail", :value => :url, :as => :image)
    Feedjira::Feed.add_common_feed_entry_element("media:content", :value => :url, :as => :image)
  end

  def insert_entry(e)
    description = e.content || e.summary || ""
    self.entries.create(title:       (e.title if not e.title.blank?),
                        description: sanitize(strip_tags(description)).first(300),
                        pub_date:    find_pub_date(e.published),
                        image:       find_image(e, description),
                        url:         e.url)
  end

  def find_pub_date(date)
    if date.nil? or date > Time.zone.now
      Time.zone.now
    else
      date
    end
  end

  def find_image(entry, description)
    return process_image(find_image_from_description(description)) ||
           process_image(entry.image)
  end

  def process_image(img)
    if img.nil? || img.blank?
      return nil
    end

    if img.start_with? '//'
      img = "http:" + img
    elsif img.start_with? '/'
      parse = URI.parse(self.site_url || self.feed_url)
      img = parse.scheme + '://' + parse.host + img
    elsif img.start_with? '../'
      parse = URI.parse(self.site_url || self.feed_url)
      img = parse.scheme + '://' + parse.host + img[2..-1]
    elsif !img.start_with? 'http'
      parse = URI.parse(self.site_url || self.feed_url)
      # parse.path is bogus if site_url doesn't exist
      img = parse.scheme + '://' + parse.host + parse.path + img
    end

    return filter_image img
  end

  def find_image_from_description(description)
    begin
      doc = Nokogiri::HTML description
      doc.css('*').each do |e|
        if e.name == "img"
          return e.attributes['src'].value
        elsif e.name == "p" && !e.text.blank?
          break
        end
      end
    rescue
    end
    return nil
  end

  def find_og_image(url)
    begin
      doc = Nokogiri::HTML(open(URI::escape(url.strip.split(/#|\?/).first)))
      return doc.css("meta[property='og:image']").first.attributes['content'].value
    rescue
    end
  end

  def filter_image(img)
    # resize techcrunch images
    if img.include? 'images.wrc.com'
      img += '_896x504.jpg'
    end

    # discard silly images
    if img.include? 'feedburner' or
      # img.include? 'pml.png' or
      # img.include? 'rc.img' or
      # img.include? 'mf.gif' or
      # img.include? 'ptq.gif' or
      # img.include? 'twitter16.png' or
      # img.include? 'sethsblog' or
      # img.include? 'assets.feedblitz.com/i/' or
      # img.include? 'wirecutter-deals' or
      # img.include? '/heads/' or
      # img.include? '/share/' or
      # img.include? 'smile.png' or
      # img.include? 'blank.' or
      # img.include? 'application-pdf.png' or
      # img.include? 's-US_UK_CA-mini' or
      # img.include? 'gif;base64' or
      # img.include? 'abrirpdf.png' or
      # img.include? 'gravatar.com/avatar' or
      # img.include? 'nojs.php' or
      # img.include? 'icon' or
      # img.include? 'gplus-16.png' or
      # img.include? 'logo' or
      # img.include? 'avw.php' or
      # img.include? 'service_links' or
      # img.include? 'tmn-test' or
      # img.include? '-ipad-h' or
      # img.include? 'webkit-fake-url' or
      # img.include? '/img/oglobo.jpg' or
      # img.include? 'beacon' or
      # img.include? 'usatoday-newstopstories' or
      # img.include? 'a2.img' or
      # img.include? 'ach.img' or
      # img.include? '/comments/' or
      # img.include? '/smilies/' or
      # img.include? 'simple-share-buttons-adder' or
      # img.include? 'a2t.img' or
      # img.include? 'a2t2.img' or
      # img.include? 'default-thumbnail' or
      # img.include? 'subscribe' or
      # img.include? 'forbes_' or
      # img.include? 'emoji' or
      # img.include? 'transparent.png' or
      # img.include? 'cdh_rss' or
      # img.include? 'ynp-rss' or
      # Disable the next to filters when og images are not used
      # img.include? 'bbcimg.co.uk' or
      # img.include? '/images/facebook' or
      # img.include? 'phys.org/newman/csz/news/tmb' or
      # img.include? 'uol-jogos-600px' or
      img.include? '.tiff' or
      img.include? '.mp3' or
      img.include? '.m4a' or
      img.include? '.mp4' or
      img.include? '.psd' or
      img.include? '.gif' or
      img.include? '.pdf' or
      img.include? '.webm' or
      img.include? '.ogv' or
      img.include? '.opus'
      return nil
    else
      return img
    end
  end

end
