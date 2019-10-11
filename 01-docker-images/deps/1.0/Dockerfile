FROM ruby:2.5.1

RUN apt update && apt install -y nodejs=4.8.2~dfsg-1

COPY Gemfile Gemfile.lock demo/
WORKDIR demo
RUN bundle install
