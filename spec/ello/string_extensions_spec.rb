require 'spec_helper'

describe 'extensions to String' do

  context '#underscore' do
    it 'underscores a camel-cased string' do
      expect('UserWasCreated'.underscore).to eq('user_was_created')
    end
  end

end
