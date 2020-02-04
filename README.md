# Meso Backend

[![CircleCI](https://circleci.com/gh/Watsi/uhp-backend.svg?style=svg&circle-token=f4ef37ba4977d42d8debccad98813b45f5742038)](https://circleci.com/gh/Watsi/uhp-backend)

The database backend and API for Meso.


## Environment setup

[Homebrew](http://mxcl.github.io/homebrew/) is recommended for installing dependencies.

`direnv` and the [.envrc](.envrc) file is used to automatically load and unload environment variables when switching into and out of the current directory. Install it via:

```shell
$ brew install direnv
$ echo 'eval "$(direnv hook bash)"' >> ~/.bash_profile # or echo 'eval "$(direnv hook $SHELL)"' >> ~/.zshrc if you use zsh
$ exec $0
$ direnv allow .
```

The app expects the following libraries to be installed, all available via Homebrew:

* `heroku` - the Heroku toolbelt helps with emulating our deployment environment locally as well as managing our Heroku apps.
* `imagemagick` - used by Dragonfly to manipulate images.

## Ruby setup

We're currently running on Ruby 2.4 and Rails 5.0.

Install and manage Ruby versions with [rvm](http://rvm.io/). Make sure to install the correct Ruby version, which is specified in the [Gemfile](Gemfile), in addition to above. No gemset is specified for this project.


## Database setup

We're currently running PostgreSQL 9.6.1.

Note that Homebrew will always install the latest version of software available, so when you install PostgreSQL you might be getting a later version of PostgreSQL than what is run in production. There is a way around this, but we haven't seen any serious problems with this mismatch of local and production environments, yet.

Install and start PostgreSQL with:

```
$ brew install postgresql
$ brew services start postgresql
```

Create a general `postgres` database user with CREATEDB and SUPERUSER privileges using the `createuser` command:

```
$ createuser -s -d postgres
```

Finally, initialize your database for the project. The development and test databases will be created and set up with the schema, and the development database seeded with default data from [scripts/demo/generate_demo_data.rb](scripts/demo/generate_demo_data.rb).
```
$ rails db:setup #(or rails db:create db:migrate)
$ rails db:seed:demo_data
```

If you want to seed the test database (i.e. for end-to-end mobile testing):

```
$ rails db:seed:demo_data RAILS_ENV=android-test
```

You can always start an interactive `psql` terminal into your development database with `$ psql uhp_backend_development`.


## Local development

##### `heroku local`
With the environment, ruby, and the database set up, you can start up the app with just `heroku local`. This starts up the API with puma at [http://localhost:5000/](http://localhost:5000/).

##### `rspec`
We use RSpec, so run specs with `rspec`, which will use the [spring](rails/spring) preloader if `direnv` is installed.

##### `shipit`
After committing, use `shipit` to pull changes from origin, run all specs, then push back up, all in one command.

### End-to-end mobile testing
For end-to-end mobile testing, you'll first need to setup `android-test` db with seed data:

##### `RAILS_ENV=android-test rails db:setup`

Then run an `android-test` server. This starts up the API with puma at [http://localhost:[port-number]/](http://localhost:[port-number]) in the android-test environment, which uses the android-test database instead of the development database.

##### `rails s -e android-test -p [port-no]`

We're setup to hit port `8000` on the android side.

## Heroku setup

We're hosted on Heroku. You'll need a Heroku account; it has worked fine to just use your personal Heroku account. Please enable two-factor authentication on your Heroku account, as it provides complete access to the production environment and database.

After you've installed the [Heroku toolbelt](https://toolbelt.heroku.com/) (`brew install heroku` works), set up your toolbelt and add our environments with:

```
$ heroku login
$ heroku keys:add
$ heroku git:remote -a uhp-backend-sandbox -r sandbox
$ heroku git:remote -a uhp-backend-demo -r demo
$ heroku git:remote -a uhp-backend-production -r production
```


## Console access

On all environments (including development), opening a Rails console requires declaring who you are – that is, entering the username of an admin user. This is not a form of authentication, since the ability to open a Rails console requires unfettered access to the Heroku environment (including database backups, etc). The user declaration merely allows for tracking who made what changes and eases future data spelunking.

## CI/CD

We're following a few best practices:

* **Continuous Integration**: Every branch and every commit, once pushed to the GitHub repo, will run its specs automatically on [CircleCI](https://circleci.com/gh/Watsi/uhp-backend).

* **Continuous Deployment**: Once our tests pass on the [master branch on CircleCI](https://circleci.com/gh/Watsi/uhp-backend/tree/master), that commit is automatically and immediately pushed to the correct heroku app. This is configured on the respective webpage settings for Heroku apps and [Docker](https://github.com/docker)/[Ouroboros](https://github.com/pyouroboros/ouroboros) for EC2 apps.

* **Zero downtime deployments**: The heroku apps have been set up with [preboot](https://devcenter.heroku.com/articles/preboot). In short, this means the Heroku router won't switch to the new release of dynos until they are fully spun up, which typically takes 3-5 minutes.

* **Automatic database migrations**: The heroku apps have been set up with a [release phase](https://devcenter.heroku.com/articles/release-phase), which will run the database migrations after the new release's slug has been built, but before new dynos have been spun up.

    The old dynos will continue to service requests during this period. This means **all database migrations must be backwards compatible**. There's a [good article](http://pedro.herokuapp.com/past/2011/7/13/rails_migrations_with_no_downtime/) on how to stage schema changes correctly and handle ActiveRecord's column cache.

* **Deployment metadata**: The heroku app has [Dyno Metadata](https://devcenter.heroku.com/articles/dyno-metadata) turned on, so you can access the current release's git SHA, etc within the code.


## Cloning data to another environment

Occasionally, it's helpful to clone the current state of one environment over to another environment to facilitate testing. With Heroku and AWS credentials, simply clone the database, restart dynos, and optionally copy over assets.

```
$ heroku pg:copy uhp-backend-production::DATABASE_URL DATABASE_URL --confirm uhp-backend-sandbox -r sandbox
$ heroku restart -r sandbox
$ aws s3 sync s3://uhp-backend-production s3://uhp-backend-sandbox
```


## Logging

Our Heroku logs are [drained](https://devcenter.heroku.com/articles/log-drains) to [LogDNA](https://app.logdna.com/1dea75e386/logs/view). The logs are archived daily to the `uhp-log-archive` bucket on S3.

For logs emitted by Rails, we use the `lograge` gem to only log one line per request. The line contains details about the request formatted in Heroku-style, key=value output for easy parsing. Here's an example log entry:

```
Mar 2 12:55:35 uhp-backend-production app[web] at=info source=app method=GET path="/providers/1/billables" request_id=1bf1afb9-15da-46e8-b9c8-73dd238a00fd format=html controller=BillablesController action=index status=304 duration=18.14ms view=0.0ms db=0.0ms
```

Other log entries are from the [Heroku stack directly](https://devcenter.heroku.com/articles/logging), our [Heroku Postgres](https://devcenter.heroku.com/articles/postgres-logs-errors) instance, or our [Heroku Redis](https://devcenter.heroku.com/articles/redis-logs-errors) instance.


## Summary

| Environment     | Name (in Heroku)       | Url                                     | Deployment | Deployed after green run on… | Purpose          |
|-----------------|------------------------|-----------------------------------------|------------|------------------------------|------------------|
| Local           | -                      | http://localhost:5000                   | manual     | -                            | Dev              |
| Test            | -                      | http://localhost:8000                   | manual     | -                            | Dev              |
