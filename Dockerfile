# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ruby
ARG RUBY_VERSION=3.0.7
ARG BASE_TAG=${RUBY_VERSION}-slim
ARG BASE=${BASE_IMAGE}:${BASE_TAG}

# -----------------------------------------------
FROM ruby:3.0.7-slim AS base
ENV LANG en_US.UTF-8

RUN apt-get update -qq \
  && apt-get install -y build-essential ca-certificates curl tzdata git libjemalloc2 libv8-dev \
  && curl -sL https://deb.nodesource.com/setup_16.x | bash \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
  && apt-get update -qq \
  && apt-get install -y nodejs yarn \
  && node -v \
  && yarn -v \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 rails && \
  useradd --uid 1000 --no-log-init --create-home --gid rails rails

ENV BUNDLE_PATH="/usr/local/bundle"

ARG BASE_RELEASE=bullseye
RUN apt-get update -qq \
  && echo "deb https://apt.postgresql.org/pub/repos/apt ${BASE_RELEASE}-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg \
  && apt-get update -qq \
  && apt-get install -y libpq-dev postgresql-client-16 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER rails
WORKDIR /app

COPY --chown=rails package.json yarn.lock Gemfile Gemfile.lock .ruby-version .tool-versions ./
COPY --chown=rails gems gems

RUN yarn install

RUN gem install bundler:2.4.20
RUN bundle install

#RUN curl https://cli-assets.heroku.com/install.sh | sh

# -----------------------------------------------
FROM base AS dev
ENV LANG en_US.UTF-8

USER rails
WORKDIR /app

COPY --chown=rails:rails --from=base "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails bin/ bin/
COPY --chown=rails:rails config/ config/

ENV RAILS_ENV=development
ENV IS_DOCKER=true
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true
ENV PORT 3000

#RUN touch /home/app/.netrc && \
    #mkdir -p tmp/pids
RUN mkdir -p tmp/pids
RUN chown rails:rails /app

# ENTRYPOINT ["bin/docker-entrypoint"]
# CMD bundle check || (bundle update --bundler && bundle install -j4 --retry 3) && foreman start
EXPOSE 5000
CMD ["bin/dev"]
