FROM ruby:2.3

ENV RAILS_ENV "production"
ENV RAILS_SERVE_STATIC_FILES "1"
ENV RAILS_LOG_TO_STDOUT "1"
ENV PUMA_OPTIONS "--preload -w 4"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget https://nodejs.org/dist/v4.6.0/node-v4.6.0-linux-x64.tar.xz \
    && tar -xvf node-v4.6.0-linux-x64.tar.xz \
    && ln -s /opt/node-v4.6.0-linux-x64/bin/node /usr/local/bin/node \
    && ln -s /opt/node-v4.6.0-linux-x64/bin/npm /usr/local/bin/npm

RUN npm install -g elm@0.18.0 \
    && ln -s /opt/node-v4.6.0-linux-x64/lib/node_modules/elm/binwrappers/* /usr/local/bin/

WORKDIR /usr/src/app

COPY Gemfile* ./
RUN bundle install

COPY package.json ./
RUN npm install

COPY elm-package.json ./
RUN elm package install --yes

COPY . .

RUN bundle exec rake assets:precompile SECRET_KEY_BASE=secret

EXPOSE 80
CMD ["bundle", "exec", "rails", "server", "-p", "80"]
