require 'spec_helper'

describe Ello::KinesisConsumer do
  it 'has a version number' do
    expect(Ello::KinesisConsumer::VERSION).not_to be nil
  end

  it 'has a logger' do
    expect(described_class.logger).to be_a(Logger)
  end
end
