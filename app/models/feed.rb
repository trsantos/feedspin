class Feed < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper

  has_many :subscriptions, dependent: :delete_all
  has_many :users, through: :subscriptions
  has_many :entries, dependent: :delete_all

  validates :feed_url, presence: true, uniqueness: true
  after_create :delayed_update

  def self.entries_per_feed
    250
  end

  def self.update_all_feeds
    Feed.find_each do |f|
      FeedUpdateJob.perform_later f
    end
  end

  def update_feed
    fj_feed = fetch_and_parse
    return if fj_feed.is_a? Integer

    transaction do
      update_entries fj_feed
      update_feed_attributes fj_feed
    end
  end

  def only_images?
    entries.each do |e|
      return false unless e.image && (strip_tags e.description).blank?
    end
    true
  end

  private

  def fetch_and_parse
    setup_fj
    xml = HTTParty.get(feed_url).body
    Feedjira.parse xml
  rescue StandardError
    update_attribute :fetching, false
    0
  end

  def update_feed_attributes(fj_feed)
    update(title: fj_feed.title,
           site_url: fj_feed.url,
           description: find_feed_description(fj_feed),
           logo: find_feed_image(fj_feed),
           has_only_images: only_images?,
           fetching: false,
           updated_at: Time.current)
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

  def check_feed_logo(logo)
    return if logo.nil?

    if (logo.include? 'wp.com/i/buttonw-com') ||
       (logo.include? 'creativecommons.org/images/public')
      nil
    else
      logo
    end
  end

  def update_entries(fj_feed)
    fj_feed.entries.reverse_each do |fj_entry|
      upsert_entry fj_entry
    end
    mark_subscriptions_as_updated
  end

  def mark_subscriptions_as_updated
    return if entries.empty?

    last_entry_pub_date = entries.last.pub_date
    subscriptions.where(updated: false, visited_at: ..last_entry_pub_date).update_all(updated: true)
  end

  def upsert_entry(fj_entry)
    description = fj_entry.content || fj_entry.summary || ''
    entries.create_with(
      title: (fj_entry.title unless fj_entry.title.blank?),
      description:,
      pub_date: find_date(fj_entry.published),
      image: find_image(fj_entry, description),
      audio: find_audio(fj_entry)
    ).find_or_create_by!(fj_entry_id: fj_entry.entry_id, url: fj_entry.url)
  end

  def setup_fj
    Feedjira::Feed.add_common_feed_entry_element('media:thumbnail', value: :url, as: :image)
    Feedjira::Feed.add_common_feed_entry_element('media:content', value: :url, as: :image)

    # Feedjira.logger.level = Logger::FATAL
  end

  def find_audio(entry)
    entry.enclosure_url if entry.enclosure_type.start_with? 'audio'
  rescue NoMethodError
    nil
  end

  def find_date(pub_date)
    return Time.current if pub_date.nil? || pub_date > Time.current

    pub_date
  end

  def find_image(entry, desc)
    process_image entry.image || image_from_description(desc)
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
