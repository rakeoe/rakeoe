require_relative 'spec_helper'


describe RakeOE::Config do
  before(:all) do
    @config = RakeOE::Config.new
  end

  it 'does create a Config object' do
    expect(@config).not_to be_nil
  end


end

describe 'Projects' do
  it 'should build a minimal project' do
    sh 'cd projects/minimal_prj && TOOLCHAIN_ENV=platform/platform_osx rake -T'
  end
end