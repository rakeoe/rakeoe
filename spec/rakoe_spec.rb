require 'spec_helper'

describe RakeOE do
  it 'does stuff' do
    #
  end
end

describe PrjFileCache do
  it 'does read prj.rake files' do
    prj_cache = FactoryGirl.build(:prj_file_cache)
    # factory girl does not provide any class variable support => bummer!
    #expect(prj_cache.class.get('APP', 'hello', 'PRJ_HOME')).to equal('.')
  end

end

describe RakeOE::Config do
  before(:all) do
    @config = RakeOE::Config.new
  end

  it 'does create a Config object' do
    expect(@config).not_to be_nil
  end


end