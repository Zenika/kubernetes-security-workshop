FROM ruby:2.5.1

RUN apt update && apt install -y nodejs=4.8.2~dfsg-1

RUN groupadd --gid 1000 rails \
  && useradd --uid 1000 --gid rails --shell /bin/bash --create-home rails
USER rails:rails

COPY --chown=rails:rails Gemfile demo/
WORKDIR demo
RUN bundle install

USER root

RUN userdel rails
