RSpec.shared_examples 'current user' do |admin:, uploader:|
  it 'returns the current user' do
    post_query

    json = JSON.parse(response.body)
    data = json['data']['currentUser']

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
