require 'spec_helper'

describe RakeOE do
  it 'does stuff' do
    pending # no code yet
  end
end

describe PrjFileCache do
  it 'does read prj.rake files' do
    prj_cache = build(:prj_file_cache)
    expect(prj_cache.class.get('APP', 'hello', 'PRJ_HOME')).to equal('.')
  end

end