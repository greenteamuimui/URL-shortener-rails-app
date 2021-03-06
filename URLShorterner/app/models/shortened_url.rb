class ShortenedUrl < ApplicationRecord
  validates :short_url, :long_url, presence: true, uniqueness: true

  def self.random_code
    url_code = SecureRandom.urlsafe_base64

    while ShortenedUrl.exists?(short_url: url_code)
      url_code = SecureRandom.urlsafe_base64
    end
    url_code
  end

  def self.user_factory(user, long_url)
    ShortenedUrl.new(user_id: user.id, long_url: long_url, short_url: ShortenedUrl.random_code)
  end

  def num_clicks
    Visit.select {|v| v.shortenedurl_id == self.id}
  end

  def num_uniques
    # self.visits.select(:user_id).count this if for without a distinct-ified visitors association
    self.visitors.count
    # Use this after using the distinct-ified version of the has_many association
  end

  def num_recent_uniques
    self.visits.select(:user_id).where("created_at > ?",10.minutes.ago).count
  end

  belongs_to :submitter,
    primary_key: :id,
    foreign_key: :user_id,
    class_name: :User

  has_many :visits,
    primary_key: :id,
    foreign_key: :shortenedurl_id,
    class_name: :Visit

  has_many :visitors,
    Proc.new { distinct },
    through: :visits,
    source: :User
end
