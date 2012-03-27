require 'spec_helper'

describe 'nested batches' do
  it 'should be able to tell current batch' do
    current = nil
    from_block = nil
    Batchy.run(:name => "this batch") do | b |
      current = Batchy.current
      from_block = b
    end

    current.should_not be_nil
    current.should == from_block
  end

  it 'should set the current batch back after completion' do
    previous = Batchy.current

    Batchy.run(:name => 'set back current') do | b |
      Batchy.current.should == b
    end

    Batchy.current.should == previous
  end

  it 'should return correct nested batch' do
    Batchy.run(:name => 'outside') do | out |

      Batchy.run(:name => 'inside') do | inside |
        Batchy.current.should == inside
      end

      Batchy.current.should == out
    end
  end

  pending 'nested batch should know parent'

end