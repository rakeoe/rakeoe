require_relative 'spec_helper'

describe 'Expanded Key-Values' do

  it 'should replace one variable' do
    h = {
        'VAL1' =>  'BLA',
        'VAL2' =>  'BLA $VAL1'
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL2']).to eq('BLA BLA')
  end


  it 'should replace not existing variable with nothing' do
    h = {
        'VAL1' =>  '$VAL2'
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL1']).to eq('')
    expect(kvr.env['VAL1'].size).to be == 0
  end

  it 'should replace later introduced variable' do
    h = {
        'VAL1' =>  '$VAL2',
        'VAL2' =>  'BLA'
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL1']).to eq('BLA')
  end

  it 'should expand single PATH variable' do
    h = {
        'VAL1' =>  '$PATH',
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL1']).not_to be_nil
    expect(kvr.env['VAL1']).to eq(ENV['PATH'])
  end

  it 'should expand PATH variable with text' do
    h = {
        'VAL1' =>  '/path/to/somewhere:$PATH',
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL1']).to eq('/path/to/somewhere:' + ENV['PATH'])
  end

  it 'should expand variable to final reference' do
    h = {
        'VAL0' =>  'BLA',
        'VAL1' =>  '$VAL0',
        'VAL2' =>  '$VAL1',
        'VAL3' =>  '$VAL2',
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL3']).to eq('BLA')
  end

  it 'should expand variable to final reference even if only forward references are used' do
    h = {
        'VAL3' =>  '$VAL2',
        'VAL2' =>  '$VAL1',
        'VAL1' =>  '$VAL0',
        'VAL0' =>  'BLA',
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL3']).to eq('BLA')
  end

  it 'should expand variable to empty if no final reference' do
    h = {
        'VAL0' =>  '$BOGUS',
        'VAL1' =>  '$VAL0',
        'VAL2' =>  '$VAL1',
        'VAL3' =>  '$VAL2',
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL3']).to eq('')
  end

  it 'should expand multiple variables in one definition' do
    h = {
        'VAL0' =>  'NICE',
        'VAL1' =>  '$VAL0',
        'VAL2' =>  '$VAL1',
        'VAL3' =>  '$VAL2 $VAL1 $VAL0',
    }
    kvr = KeyValueReader.new(h)
    expect(kvr).not_to be_nil
    expect(kvr.env['VAL3']).to eq('NICE NICE NICE')
  end

end