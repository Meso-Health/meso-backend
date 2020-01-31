%w(
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
  app/lib/exceptions_app.rb
).each { |path| Spring.watch(path) }
