require 'spec_helper'

def verify_hush(occurred)
  expect(replies.include?('quiet_room is a moderated room')).to eq(occurred)
end

describe Lita::Handlers::Hush, lita_handler: true do
  it { is_expected.to route('anything').to(:ambient) }
  it { is_expected.to route_command('room add @foo').to(:voice) }
  it { is_expected.to route_command('room remove @foo').to(:voice) }
  it { is_expected.to route_command('room status').to(:status) }
  it { is_expected.to route_command('room moderation on').to(:moderate) }
  it { is_expected.to route_command('room moderation off').to(:moderate) }

  let(:alice) do
    Lita::User.create(123, name: 'Alice', mention_name: 'alice')
  end

  let(:bob) do
    Lita::User.create(456, name: 'Bob', mention_name: 'bob')
  end

  let(:quiet_room) do
    Lita::Room.new(1, name: 'quiet_room')
  end

  let(:loud_room) do
    Lita::Room.new(2, name: 'loud_room')
  end

  before do
    send_command('room moderation on', as: alice, from: quiet_room)
  end

  describe '#add' do
    it 'adds a user to that rooms list' do
      Lita::User.create(456, name: 'Bob', mention_name: 'bob')
      send_command('room add bob', as: alice, from: quiet_room)
      expect(replies.last).to eq('Bob added to quiet_room list')
    end
  end

  describe '#ambient' do
    it 'does nothing in rooms that it is not configured for' do
      send_message('foo', as: alice, from: loud_room)
      send_message('foo', as: bob, from: loud_room)
      verify_hush(false)
    end

    it 'allows people on a list to speak' do
      send_message('foo', as: alice, from: quiet_room)
      verify_hush(false)
    end

    it 'sends a message to people not on a list when they speak' do
      send_message('bar', as: bob, from: quiet_room)
      verify_hush(true)
    end
  end

  describe '#remove' do
    it 'removes a user from that rooms list' do
      send_command('room remove alice', as: alice, from: quiet_room)
      expect(replies.last).to eq('Alice removed from quiet_room list')
    end
  end

  describe '#status' do
    it 'describes the current moderation status of the room' do
      send_command('room status', as: alice, from: quiet_room)
      expect(replies.last).to eq('Room is moderated')
      send_command('room status', as: alice, from: loud_room)
      expect(replies.last).to eq('Room is unmoderated')
    end

    it 'does not PM if an unapproved user asks in a moderated room' do
      send_command('room status', as: bob, from: quiet_room)
      expect(replies.last).to eq('Room is moderated')
      verify_hush(false)
    end
  end

  describe '#unmoderate' do
    it 'unmoderates a moderated room' do
      send_command('room moderation off', from: quiet_room)
      expect(replies.last).to eq('Room now unmoderated')
    end
  end
end
