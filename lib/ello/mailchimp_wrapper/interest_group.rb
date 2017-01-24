class InterestGroup
  class << self
    def find_or_create_interest_group_id(category_name, interest_group_name)
      interest_group_name = interest_group_name.downcase
      interest_groups = find_or_fetch_category(category_name)
      if interest_groups.has_key?(interest_group_name)
        interest_groups[interest_group_name]
      else
        create_interest_group(category_name, interest_group_name)
      end
    end

    private

    def users_list
      gibbon.lists(ENV['MAILCHIMP_USERS_LIST_ID'])
    end

    def gibbon
      Gibbon::Request.new
    end

    def find_or_fetch_category(category_name)
      @categories ||= {}
      @categories[category_name] ||= begin
        category_id = find_category_id_from_name(category_name)
        fetch_interest_groups_for_category_id(category_id)
      end
    end

    def find_category_id_from_name(category_name)
      users_list.interest_categories.retrieve['categories'].detect { |c| c['title'] == category_name }['id']
    end

    def fetch_interest_groups_for_category_id(id)
      mailchimp_categories = []
      offset = 0
      count = 10
      loop do
        mc_category_page = users_list.
          interest_categories(id).
          interests.
          retrieve(params: { offset: offset, count: count })['interests']
        break if mc_category_page.empty?
        mailchimp_categories = mailchimp_categories + mc_category_page
        offset += count
      end
      mailchimp_categories.each_with_object({}) do |mc_category, mc_categories|
        mc_categories[mc_category['name'].downcase] = mc_category['id']
      end
    end

    def create_interest_group(category_name, interest_group_name)
      id = find_category_id_from_name(category_name)
      ig_id = users_list.
        interest_categories(id).
        interests.
        create(body: { name: interest_group_name.capitalize })['id']
      @categories[category_name][interest_group_name] = ig_id
      ig_id
    end
  end
end
