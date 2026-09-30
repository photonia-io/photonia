# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrecomputeSearchTermsJob do
  def terms
    SearchTerm.pluck(:term)
  end

  it "extracts words from public photos' titles and descriptions" do
    create(:photo, title: 'Sunset over the mountains', description: 'A lovely evening')

    described_class.perform_now

    expect(terms).to include('sunset', 'mountains', 'lovely', 'evening')
  end

  it 'extracts words from tags and public album titles' do
    photo = create(:photo)
    photo.tag_list.add('waterfall')
    photo.save!
    album = create(:album, title: 'Carpathians', privacy: 'public')
    album.photos << photo

    described_class.perform_now

    expect(terms).to include('waterfall', 'carpathians')
  end

  it 'excludes a private photo entirely' do
    create(:photo, privacy: 'private', title: 'Secretgarden')

    described_class.perform_now

    expect(terms).not_to include('secretgarden')
  end

  it "excludes a private album's title" do
    photo = create(:photo)
    album = create(:album, title: 'Privatealbumtitle', privacy: 'private')
    album.photos << photo

    described_class.perform_now

    expect(terms).not_to include('privatealbumtitle')
  end

  it 'counts the number of distinct photos a word appears on' do
    create_list(:photo, 3, title: 'lighthouse')
    create(:photo, title: 'something else')

    described_class.perform_now

    expect(SearchTerm.find_by(term: 'lighthouse').photos_count).to eq(3)
  end

  it 'drops words shorter than 3 characters' do
    create(:photo, title: 'ab cd sea')

    described_class.perform_now

    expect(terms).not_to include('ab', 'cd')
    expect(terms).to include('sea')
  end

  it 'drops purely numeric words' do
    create(:photo, title: '2024 vacation')

    described_class.perform_now

    expect(terms).not_to include('2024')
    expect(terms).to include('vacation')
  end

  it 'strips accents so a search matches either spelling' do
    create(:photo, title: 'Café')

    described_class.perform_now

    expect(terms).to include('cafe')
  end

  it 'fully replaces the table on each run' do
    create(:search_term, term: 'stale')
    create(:photo, title: 'fresh', description: nil)

    described_class.perform_now

    expect(terms).not_to include('stale')
    expect(terms).to include('fresh')
  end
end
