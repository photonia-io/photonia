# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'recentComments Query' do
  subject(:comments) do
    post '/graphql', params: { query: }
    response.parsed_body.dig('data', 'recentComments')
  end

  let(:distinct) { false }
  let(:limit) { 5 }
  let(:query) do
    <<~GQL
      query {
        recentComments(limit: #{limit}, distinct: #{distinct}) {
          id
          snippet
          authorName
          commentsCount
          photo { id }
          album { id }
        }
      }
    GQL
  end

  let(:photo) { create(:photo) }

  def comment_on(commentable, body: 'Nice one', at: Time.current, **attrs)
    create(:comment, commentable:, body:, created_at: at, **attrs)
  end

  it 'lists the newest comments first, with author and target' do
    older = comment_on(photo, body: 'Older', at: 2.days.ago)
    newer = comment_on(photo, body: 'Newer', at: 1.day.ago)

    expect(comments.map { |c| c['id'] }).to eq([newer.serial_number.to_s, older.serial_number.to_s])
    expect(comments.first).to include(
      'authorName' => newer.user.public_name, 'commentsCount' => 2, 'photo' => { 'id' => photo.slug }, 'album' => nil
    )
  end

  it 'comments on albums point at the album' do
    album = create(:album)
    album.photos << photo
    album.maintenance
    comment_on(album)

    expect(comments.first).to include('photo' => nil, 'album' => { 'id' => album.slug })
  end

  it 'excludes comments on private photos and on albums without public photos' do
    comment_on(create(:photo, privacy: 'private'))
    album = create(:album)
    album.maintenance
    comment_on(album)

    expect(comments).to be_empty
  end

  it 'names a Flickr author by real name, falling back to username' do
    flickr_user = create(:flickr_user, realname: 'Jane Flickr')
    create(:comment, :with_flickr_user, user: nil, flickr_user:, commentable: photo)

    expect(comments.first['authorName']).to eq('Jane Flickr')
  end

  it 'turns the body into a short plain-text snippet' do
    comment_on(photo, body: "**Great** shot &amp; light #{'word ' * 60}")

    snippet = comments.first['snippet']
    expect(snippet).to start_with('Great shot')
    expect(snippet.length).to be <= 140
    expect(snippet).not_to include('<', '**')
  end

  context 'when distinct' do
    let(:distinct) { true }

    it 'returns only the newest comment of each photo or album' do
      other = create(:photo)
      comment_on(photo, body: 'old on photo', at: 3.days.ago)
      latest = comment_on(photo, body: 'new on photo', at: 1.day.ago)
      other_comment = comment_on(other, at: 2.days.ago)

      expect(comments.map { |c| c['id'] }).to eq([latest.serial_number.to_s, other_comment.serial_number.to_s])
      expect(comments.first['commentsCount']).to eq(2)
    end
  end
end
