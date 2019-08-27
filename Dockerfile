FROM ruby:2.5.1

RUN apt update && apt install -y nodejs=4.8.2~dfsg-1

COPY demo demo
WORKDIR demo
RUN bundle install

ENTRYPOINT ["rails","s","--binding","0.0.0.0"]
