# Dockerfile that attempts to match the ruby environment used by Heroku
#     ref: https://github.com/heroku/stack-images/issues/56#issuecomment-348246257
#
# Uses a multi-stage build so that dependencies required only
#     for the buildpack are not used in the final image
#
# Requres the following ENV variables to be set when building:
#     SECRET_KEY_BASE
#

FROM heroku/heroku:16-build as build
COPY . /app
WORKDIR /app
RUN mkdir -p /tmp/buildpack/ruby /tmp/build_cache /tmp/env
RUN curl https://codon-buildpacks.s3.amazonaws.com/buildpacks/heroku/ruby.tgz | tar --warning=none -xz -C /tmp/buildpack/ruby

ENV STACK=heroku-16
RUN /tmp/buildpack/ruby/bin/compile /app /tmp/build_cache /tmp/env

FROM heroku/heroku:16
COPY --from=build /app /app
ENV HOME /app
WORKDIR /app

# set all the ENV variables specified in the .profile.d/ruby.sh file created by the heroku ruby buildpack
ENV LANG="en_US.UTF-8"
ENV GEM_PATH="$HOME/vendor/bundle/ruby/2.4.0:$GEM_PATH"
ENV PATH="$HOME/bin:$HOME/vendor/bundle/bin:$HOME/vendor/bundle/ruby/2.4.0/bin:$PATH"
ENV RAILS_ENV=docker
ENV RACK_ENV=docker
ENV RAILS_LOG_TO_STDOUT=enabled
ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE

# assumes DB has been created and migrations ran
CMD bundle exec rake db:migrate && bundle exec puma -C config/puma.rb
