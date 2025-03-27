class Feed < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper

  has_many :subscriptions, dependent: :delete_all
  has_many :users, through: :subscriptions
  has_many :entries, dependent: :delete_all

  validates :feed_url, presence: true, uniqueness: true
  after_create :delayed_update

  ENTRIES_PER_FEED = 150

  def self.update_all_feeds
    Feed.find_each do |f|
      FeedUpdateJob.perform_later f
    end
  end

  def update_feed
    fj_feed = fetch_and_parse
    return if fj_feed.nil?

    transaction do
      upsert_entries fj_feed
      update_feed_attributes fj_feed
    rescue StandardError
      update_attribute(:modified_at, nil)
    end
  end

  private

  def fetch_and_parse
    feedjira_setup
    xml = fetch_feed_body
    Feedjira.parse xml
  rescue StandardError
    update_attribute(:fetching, false)
    nil
  end

  def fetch_feed_body
    if modified_at.present?
      http_date = modified_at.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')
      options = { headers: { "If-Modified-Since": http_date } }
      response = HTTParty.get(feed_url, options)
    else
      response = HTTParty.get(feed_url)
    end
    update_attribute(:modified_at, response.headers['last-modified']) if response.headers.key?('last-modified')
    response.body
  end

  def update_feed_attributes(fj_feed)
    update(title: fj_feed.title,
           site_url: fj_feed.url,
           description: find_feed_description(fj_feed),
           logo: find_feed_image(fj_feed),
           fetching: false)
  end

  def find_feed_image(fj_feed)
    fj_feed.image.url
  rescue StandardError
    nil
  end

  def find_feed_description(fj_feed)
    fj_feed.description
  rescue StandardError
    nil
  end

  def upsert_entries(fj_feed)
    old_entries_count = entries.count
    fj_feed.entries.first(ENTRIES_PER_FEED).reverse_each do |fj_entry|
      upsert_entry(fj_entry)
    end
    return unless entries.count > old_entries_count

    discard_old_entries
    mark_subscriptions_as_updated
  end

  def discard_old_entries
    subquery = entries.order(updated_at: :desc).limit(ENTRIES_PER_FEED).select(:id)
    entries.where.not(id: subquery).delete_all
  end

  def mark_subscriptions_as_updated
    return if entries.empty?

    subscriptions.where(updated: false).update_all(updated: true)
  end

  def upsert_entry(fj_entry)
    entry_params = build_entry_params(fj_entry)
    entries.upsert(entry_params, unique_by: %i[feed_id fj_entry_id])
  end

  def build_entry_params(fj_entry)
    audio = find_audio(fj_entry)
    description = fj_entry.content || fj_entry.summary || ''
    has_text = !strip_tags(description).blank?
    image = find_image(fj_entry, description)
    pub_date = find_date(fj_entry.published)
    title = find_title(fj_entry)

    { audio:, description:, feed_id: id, fj_entry_id: fj_entry.id,
      has_text:, image:, pub_date:, title:, url: fj_entry.url }
  end

  def feedjira_setup
    Feedjira::Feed.add_common_feed_entry_element('media:thumbnail', value: :url, as: :image)
    Feedjira::Feed.add_common_feed_entry_element('media:content', value: :url, as: :image)

    # Feedjira.logger.level = Logger::FATAL
  end

  def from_enclosure(entry, type)
    entry.enclosure_url if entry.enclosure_type.start_with? type
  rescue NoMethodError
    nil
  end

  def find_title(entry)
    entry.title unless entry.title.blank?
  end

  def find_audio(entry)
    from_enclosure(entry, 'audio')
  end

  def find_date(pub_date)
    [pub_date, Time.current].compact.min
  end

  def find_image(entry, desc)
    image = entry.image || from_enclosure(entry, 'image') || image_from_description(desc)
    process_image image
  end

  def process_image(img)
    return nil if img.nil?

    parse_image img
  end

  def parse_image(img)
    # Need to add http here as some images won't
    # load because ssl_error_bad_cert_domain
    return 'http:' + img if img.start_with?('//')

    uri = URI.parse feed_url
    start = uri.scheme + '://' + uri.host
    return start + img if img.start_with? '/'

    # I don't remeber why this is here. Maybe not needed?
    return start + uri.path + img unless img.start_with? 'http'

    img
  end

  def image_from_description(description)
    doc = Nokogiri::HTML description
    doc.css('img').first.attributes['src'].value
  rescue StandardError
    nil
  end

  def delayed_update
    FeedUpdateJob.set(queue: :critical).perform_later(self)
  end
end
