require 'spec_helper'

describe Transmap do

  it 'should be able to configure logger' do

    logger = Logger.new(STDOUT)

    Transmap.configure do |config|
      config.logger = logger
    end

    expect(Transmap.logger).to be(logger)

  end


end