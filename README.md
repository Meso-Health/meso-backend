# Meso Backend

[![CircleCI](https://circleci.com/gh/Meso-Health/meso-backend.svg?style=svg)](https://circleci.com/gh/Meso-Health/meso-backend)

A Rails API and system administration dashboard for the Meso platform


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

We're currently running on Ruby 2.6 and Rails 5.1.

Install and manage Ruby versions with [rvm](http://rvm.io/). Make sure to install the correct Ruby version, which is specified in the [Gemfile](Gemfile), in addition to above. No gemset is specified for this project.


## Database setup

We're currently running PostgreSQL 9.6.9.

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

You can always start an interactive `psql` terminal into your development database with `$ psql meso_backend_development`.


## Local development

##### `heroku local`
With the environment, ruby, and the database set up, you can start up the app with just `heroku local`. This starts up the API with puma at [http://localhost:5000/](http://localhost:5000/).

##### `rspec`
We use RSpec, so run specs with `rspec`, which will use the [spring](rails/spring) preloader if `direnv` is installed.

## Heroku setup

To deploy the application to Heroku, you'll need a Heroku account; it has worked fine to just use your personal Heroku account. Please enable two-factor authentication on your Heroku account, as it provides complete access to the deployed environment and database.

After you've installed the [Heroku toolbelt](https://toolbelt.heroku.com/) (`brew install heroku` works), set up your toolbelt:

```
$ heroku login
$ heroku keys:add
```

## Console access

On all environments (including development), opening a Rails console requires declaring who you are – that is, entering the username of an admin user. This is not a form of authentication, since the ability to open a Rails console requires unfettered access to the deployed environment (including database backups, etc). The user declaration merely allows for tracking who made what changes and eases future data spelunking.

## CI/CD

* **Continuous Integration**: Every branch and every commit, once pushed to the GitHub repo, will run its specs automatically on [CircleCI](https://circleci.com/gh/Meso-Health/meso-backend).

## Logging

For logs emitted by Rails, we use the `lograge` gem to only log one line per request. The line contains details about the request formatted in Heroku-style, key=value output for easy parsing. Here's an example log entry:

```
Mar 2 12:55:35 meso app[web] at=info source=app method=GET path="/providers/1/billables" request_id=1bf1afb9-15da-46e8-b9c8-73dd238a00fd format=html controller=BillablesController action=index status=304 duration=18.14ms view=0.0ms db=0.0ms
```
