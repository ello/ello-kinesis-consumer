require 'gibbon'
require 'digest'
require_relative 'mailchimp_wrapper/user_interest_groups.rb'

class MailchimpWrapper

  def remove_from_users_list(email)
    hash = subscriber_hash(email)
    begin
      users_list.members(hash).update(body: { status: 'unsubscribed' })
    rescue Gibbon::MailChimpError => e
      raise e unless e.status_code == 404
    end
  end

  def upsert_to_users_list(email:, preferences:, categories: [], featured_categories: [], merge_fields: {}, force_resubscribe: false)
    return if skip_list.include?(email)
    hash = subscriber_hash(email)
    body = {
      email_address: email,
      merge_fields: merge_fields,
      interests: UserInterestGroups.new(preferences: preferences).as_json
    }.merge((force_resubscribe ? :status : :status_if_new) => determine_subscription_status(email, force_resubscribe))
    begin
      users_list.members(hash).upsert(body: body)
    rescue Gibbon::MailChimpError => e
      # Ideally this would be more specific, but they don't let us just check the e-mail field
      raise e unless e.status_code == 400
    end
  end

  private

  def skip_list
    (ENV['EMAILS_TO_SKIP'] || '').split(',').map { |email| email.tr('.', '') }.map(&:strip)
  end

  def users_list
    gibbon.lists(ENV['MAILCHIMP_USERS_LIST_ID'])
  end

  def subscriber_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def determine_subscription_status(email, force_resubscribe)
    if force_resubscribe
      status = existing_subscriber_status(email)
      status == 'unsubscribed' ? 'pending' : 'subscribed'
    else
      'subscribed'
    end
  end

  def existing_subscriber_status(email)
    begin
      users_list.members(subscriber_hash(email)).retrieve['status']
    rescue Gibbon::MailChimpError => _
      puts "#{email} is not an existing subscriber."
    end
  end

  def gibbon
    Gibbon::Request.new
  end
end
