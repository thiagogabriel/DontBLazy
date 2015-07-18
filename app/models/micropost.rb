class Micropost < ActiveRecord::Base
  belongs_to :user
  default_scope -> { order('created_at DESC') }
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :title, presence: true, length: { minimum: 5, maximum: 50 }
  validates :content, presence: true, length: { maximum: 140 }
  validate  :picture_size
  # DBL
  has_many :micropost_recipients, dependent: :destroy
  has_many :recipients, through: :micropost_recipients
  validates :schedule_time, presence: true
  after_create :schedule_user_deadline_text
  after_create :send_status_sms


  # DBL Logic

  # Schedules a SMS sent out at deadline.
  def schedule_user_deadline_text
    # Starts SINGULAR 24 hour delay then sends deadline SMS at that time.
    job = self.delay(run_at: 24.hours.from_now).send_text_messages(deadline_text_content)
    update_column(:delayed_job_id, job.id)
  end

  def delayed_job
    Delayed::Job.find(delayed_job_id)
  end

  # Twilio magic
  def send_text_message(content, target_phone)

    twilio_sid = ENV["TWILIO_ACCOUNT_SID"]
    twilio_token = ENV["TWILIO_AUTH_TOKEN"]
    twilio_phone_number = ENV["TWILIO_PHONE_NUMBER"]

    @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token

      @twilio_client.messages.create(
        :from => twilio_phone_number,
        :to => target_phone,
        :body => content
      )
  end

  # UNTESTED by Rspec
  # Send user's phone a SMS list of active goals menu on create
  def send_status_sms
    user = User.find_by(:id => self.user_id)
    goals = user.microposts
    arr = [], i = 0
    goals.each do |goal|
      i += 1
      sms = i.to_s + ". " + goal.title
      arr << sms 
    end
    # trim 0 with string match here
    active_goals = arr.join(" ")
    active_goals_summary = "Thank you! To mark a task complete, REPLY with your goal's corresponding number:" + active_goals
    send_text_message(active_goals_summary, user.phone_number)
  end
  
  
  private
  
    # Validates the size of an uploaded picture.
    def picture_size
      if picture.size > 5.megabytes
        errors.add(:picture, "should be less than 5MB")
      end
    end
end
