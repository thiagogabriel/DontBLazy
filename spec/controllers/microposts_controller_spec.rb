require 'rails_helper'
RSpec.describe MicropostsController, :type => :controller do
  
  before(:each) do
    user = create(:user)
    content = user.create(:micropost_with_recipients)
    log_in(user)
  end

  describe 'GET #home'
    # User logging into home and seeing a list of followed's and personal tasks (microposts)
    it "populates an array of followed's tasks (microposts) by most recent date" do
  end

  describe 'POST #schedule' 
  	it "only at time specified by its scheduled_time column" do
  	  expect(logged_in?).to eq(true)
  	  expect(recipients_present?(@more_content)).to eq(true) #fail
      expect_micropost_to_have_at_least_one_recipient
  	  expect(Delayed::Job.count).to eq(1)
  	  scheduled_time_of_test_sms = Time.utc(2015, 7, 15, 22, 0, 0)
  	  expect(Micropost.first.scheduled_time).to eq(scheduled_time_of_test_sms)
  	  Timecop.travel(Time.now + 5.days)
  	  successes, failures = Delayed::Worker.new.work_off
  	  expect(successes).to eq(1)
  	  expect(failures).to eq(0)
  	  expect(Delayed::Job.count).to eq(0)
  	  expect(Micropost.first.sms_sent).to eq(true)
  	end
end
	
  # ARCHIVE TESTS
  #
  # # Remember to update scheduled time if testing
  # describe 'will schedule and send sms' do
  # 	before :each do
  # 	  test_time = Time.utc(2015, 7, 6, 22, 0, 0)
  # 	  Timecop.freeze(test_time)
  # 	end
  # 	after(:each) { Timecop.return }
