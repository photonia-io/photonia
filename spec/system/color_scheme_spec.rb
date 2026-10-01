# frozen_string_literal: true

require 'rails_helper'

describe 'Color scheme switcher' do
  before { create(:photo, image_data: TestData.image_data) }

  def emulate_os_scheme(scheme)
    page.driver.browser.page.command(
      'Emulation.setEmulatedMedia',
      features: [{ name: 'prefers-color-scheme', value: scheme }]
    )
  end

  def page_background
    page.evaluate_script('getComputedStyle(document.body).backgroundColor')
  end

  def toggle
    find('.navbar-end .icon.is-clickable').click
  end

  def light_background?
    page_background == 'rgb(255, 255, 255)'
  end

  %w[light dark].each do |os_scheme|
    other = os_scheme == 'light' ? 'dark' : 'light'

    context "with the OS in #{os_scheme} mode" do
      before do
        emulate_os_scheme(os_scheme)
        visit root_path
        expect(page).to have_css("html[data-theme='#{os_scheme}']")
      end

      it "follows the OS on first load and switches to #{other}" do
        expect(light_background?).to eq(os_scheme == 'light')

        toggle
        expect(page).to have_css("html[data-theme='#{other}']")
        expect(light_background?).to eq(other == 'light')
      end

      it "keeps the #{other} choice after a reload" do
        toggle
        expect(page).to have_css("html[data-theme='#{other}']")

        visit root_path
        expect(page).to have_css("html[data-theme='#{other}']")
        expect(light_background?).to eq(other == 'light')
      end
    end
  end
end
