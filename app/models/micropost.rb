class Micropost < ActiveRecord::Base
  belongs_to :user
  default_scope -> { order('created_at DESC') }
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :title, presence: true, length: { minimum: 5, maximum: 50 }
  validates :content, length: { maximum: 140 }
  validate  :picture_size
  # DBL
  has_many :micropost_recipients, dependent: :destroy
  has_many :recipients, through: :micropost_recipients
  validates :days_to_complete, presence: true
  accepts_nested_attributes_for :micropost_recipients

  # To run daemon:
  # bin/delayed_job start

  # To find status:
  # bin/delayed_job status

  # To delete all DJs:
  # rake jobs:clear 

  # To turn on listening port in ngrok:
  # cd Desktop
  # ./ngrok http 3000

  # Sets a default state for every freshly minted Micropost (goal)
  def set_initial_state
    self.check_in_current = false
    self.days_completed = 0
    self.days_remaining = self.days_to_complete 
    self.current_day = 1
    self.active = true
    self.save
  end

  def next_day_tally
      self.days_remaining -= 1  # DB Column
      self.current_day += 1     # DB Column
      self.check_in_current = false
      self.save
  end

  # Clean up INACTIVE tasks
  def inactive_cleanup
    # Finds referenced micropost from user's map and deletes itself
    user = User.find_by(:id => self.user_id)
    user.current_tasks_map = user.current_tasks_map.delete_if {|h| h["micropost id"] == self.id}
    user.save

    # Finds and removes all associated Delayed Jobs still lurking in the system
    garbage_jobs = Delayed::Job.where(:owner_type => "Micropost", 
                                      :owner_id => self.id
                                    )
    garbage_jobs.each do |job|
      job.delete
    end
  end

  # Provides mapping of goals with active deadlines
  def send_user_status_sms
    user = User.find_by(:id => self.user_id)
    user.send_status_sms
  end

  def send_day_completed_sms
    user = User.find_by(:id => self.user_id)
    activity = self.title
    day_completed_message = "Thank you for checking in to your task: " + activity + "! Such a hard worker :p"
    send_text_message(day_completed_message, user.phone_number)
  end

  def send_day_incomplete_sms
    user = User.find_by(:id => self.user_id)
    activity = self.title
    current_day = self.current_day.to_s

    day_incomplete_message = "You missed day " + current_day + " of your task: " + activity + ". Time to get serious!"
    send_text_message(day_incomplete_message, user.phone_number)
  end

  def send_bad_news_to_buddies
    user = User.find_by(:id => self.user_id)
    first_name = user.name
    last_name = user.last_name
    recipients = self.recipients
    activity = self.title

    shaming_message = "DontBLazy App: Your friend " + first_name + " " + last_name + " has promised to do task:" + activity + ". " + "They missed their goal today, tsk tsk! www.dontbelazy.today"
    recipients.each do |recipient|
      send_text_message(shaming_message, recipient.phone)
    end
  end

  def send_four_hour_reminder  
    user = User.find_by(:id => self.user_id)
    activity = self.title
    num = user.current_tasks_map.find{|id| id["micropost id"] == self.id}["task"]
    num_string = num.to_s
    day = self.current_day
    day_string = day.to_s
    four_hour_message = "DontBLazy App: This is a reminder to complete day " + day_string + " of your task: " + activity + ". Check in via www.dontbelazy.today or reply to this text with the number -> " + num_string + ". You have four hours remaining."
    send_text_message(four_hour_message, user.phone_number)
  end

  # After 24 hours, DBL runs this check-in
  def check_in 
    # User already checked in thru SMS before deadline
    if self.check_in_current == true
      next_day_tally
      schedule_new_day if self.days_remaining > 0
      inactive_cleanup if self.days_remaining == 0 # Checks if days_remaining > 0 and schedules a new day (24 hour + 4 hour reminder)
      self.check_in_current = false  # Sets this column for next day
      self.save
    else 
    # User has NOT checked in via SMS or website and is NOW DUE
      send_day_incomplete_sms # THIS ALWAYS GOES FIRST b/c CURRENT_DAY 
      next_day_tally # THEN YOU UPDATE THE DB TALLIES
      send_bad_news_to_buddies if !self.recipients.empty?
      schedule_new_day if self.days_remaining > 0
      if self.days_remaining == 0
        inactive_cleanup 
        self.active = false
      end
      self.check_in_current = false  # Sets this column for next day
      self.save
    end
  end

  # Finds Micropost from mapped number and checks it in
  def checking_in_number
    self.days_completed += 1
    self.check_in_current = true
    next_day = self.current_day + 1
    if next_day > self.days_to_complete # For real time feedback
      self.active = false 
      self.inactive_cleanup
    end
    self.save

    # Since you already checked in, delete reminder to check in again
    sms_reminder_jobs = Delayed::Job.where(:owner_type => "Micropost", 
                                           :owner_id => self.id, 
                                           :owner_job_type => "4 Hour Reminder"
                                          )
    sms_reminder_jobs.each do |job|
      job.delete
    end
  end

  # Schedule multiple delayed job based on number of days and task
  def schedule_check_in_deadline
    #if !ENV == test
    job = self.delay(run_at: 24.hours.from_now).check_in 
    update_column(:delayed_job_id, job.id)  # Update Delayed_job
    Delayed::Job.find_by(:id => job.id).
      update_columns(
        owner_type: "Micropost",
        owner_job_type: "24 Hour Deadline",
        owner_id: self.id,
        user_id: self.user_id,
      )
  end

  def schedule_four_hour_reminder  # eventually 4 hours will be a variable 
    job = self.delay(run_at: 20.hours.from_now).send_four_hour_reminder
    update_column(:delayed_job_id, job.id)  # Update Delayed_job
    Delayed::Job.find_by(:id => job.id).
      update_columns(
        owner_type: "Micropost",
        owner_job_type: "4 Hour Reminder",
        owner_id: self.id,
        user_id: self.user_id
      )
  end

  def schedule_new_day
    schedule_check_in_deadline  # Full day job
    schedule_four_hour_reminder  # Reminder
  end

  # Checks to see if selected Micropost is NOT already checked in
  def fresh_and_not_checked_in?
    !false ^ self.check_in_current
    # returns TRUE if it's CLEAN and hasn't been checked into
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

  # Associates Delayed Jobs with "owners" models
  def foo
  end
  handle_asynchronously :foo, :owner => Proc.new { |o| o  }

  private
  
    # Validates the size of an uploaded picture.
    def picture_size
      if picture.size > 5.megabytes
        errors.add(:picture, "should be less than 5MB")
      end
    end
end
 