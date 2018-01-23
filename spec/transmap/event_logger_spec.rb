require 'spec_helper'

describe Transmap::EventLogger do

  it 'should be able to log an event' do

    ev = Transmap::EventLogger.new

    expect(Transmap.logger).to receive(:debug).once

    ev.call('test',Time.now,Time.now,'test_id',{data: 'test'})
    
  end


end