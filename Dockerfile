# Dockerfile - Development environment
FROM ruby:2.6.7

# the ever necessary
RUN apt-get update

# nodejs
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
# RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
# RUN apt-get install -y --no-install-recommends nodejs yarn

# other dependencies
RUN apt-get install -y postgresql-client
RUN apt-get install -y libexif-dev

# Create and switch to app directory
WORKDIR /usr/src/app

# bundle install
RUN gem install bundler:2.2.26
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 5

# yarn install
# COPY package.json .
# COPY yarn.lock .
# RUN yarn install
