# Use a specific version of Ruby
FROM public.ecr.aws/docker/library/ruby:3.2.2-bookworm AS base

# Set the working directory
WORKDIR /rails

# Set production environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce the size of the final image
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      pkg-config \
      postgresql-client \
      libvips \
      libpq-dev \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Copy and install gem dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code and precompile assets
COPY . .

# Create a non-root user and set permissions
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp

# Switch to the non-root user
USER rails:rails

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
