FROM ruby:2.2
COPY . /usr/src/app
WORKDIR /usr/src/app
RUN bundle install

