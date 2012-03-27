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

  it 'should return correct nested batch' do
    inside_batch_id = nil
    current_batch_id = nil
    Batchy.run(:name => 'outside') do | out |

      Batchy.run(:name => 'inside') do | inside |
        inside_batch_id = inside.id
        current_batch_id = Batchy.current.id
      end

    end

    current_batch_id.should_not be_nil
    current_batch_id.should == inside_batch_id
  end

  it 'should know its parent if nested' do
    outer_id = nil
    parent_id = nil
    Batchy.run(:name => 'outside') do | out |
      outer_id = out.id

      Batchy.run(:name => 'inside') do | inside |
        parent_id = Batchy.current.parent.id
      end

    end

    parent_id.should == outer_id
  end

  it 'should set the current batch back after exiting nested branch' do
    outer = 'outer'
    current = 'parent'
    Batchy.run(:name => 'outside') do | out |
      outer = out

      Batchy.run(:name => 'inside') do | inside |
        parent_batch = Batchy.current.parent
      end

      current = Batchy.current
    end

    outer.should_not be_nil
    current.should == outer
  end

  it 'should set current to nil outside of a block' do
    Batchy.run(:name => 'outside') do | out |
      # do something
    end

    Batchy.current.should be_nil
  end

end