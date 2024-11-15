RSpec.shared_examples 'user settings' do |admin:, uploader:|
  it 'returns the user settings' do
    post_query

    json = JSON.parse(response.body)
    data = json['data']['userSettings']

    expect(data).to include(
      'id' => user.slug,
      'email' => email,
      'firstName' => first_name,
      'lastName' => last_name,
      'displayName' => display_name,
      'timezone' => { 'name' => timezone },
      'admin' => admin,
      'uploader' => uploader
    )
  end
end
