class GuestBookController < ApplicationController
  def index
    @new_entry = GUEST::Entry.new(unique_uri)
    @entries = GUEST::Entry.find_all
  end

  def sign
    @entry = GUEST::Entry.new(unique_uri)
    @entry.save
    @entry.guest::user_name = @params['new_entry']['user_name']
    @entry.guest::comments = @params['new_entry']['comments']
    redirect_to home_url
  end

  private

  def unique_uri
    "#{$guestbook_uri}thing/#{UUID.timestamp_create().to_s}"
  end
end
