ruhoh-plugin-publish-heroku
=======================

A [ruhoh](https://github.com/ruhoh/ruhoh.rb/) plugin to deploy a [Rack](https://github.com/rack/rack) version of the compiled site to [Heroku](http://www.heroku.com).

Requirements
------------
* A Heroku account and the Heroku toolbelt installed on your system.

Installation
------------
1. Clone this repo and create a symlink to it in the `plugins/publish`
i.e. `ln -s /git/location/to/ruhoh-plugin-publish-heroku ruhoh-site/plugin/publish/heroku`.
**NOTE:** You may need to create the `plugins/publish` directory if it doesn't already exist

2. Install `aws-sdk` gem and add it to the ruhoh site's Gemfile and run `bundle install`.

3. If one doesn't already exist create a `publish.json` in the root directory of the ruhoh site and add the following:
```
{
    "heroku": {
        "app": "your_heroku_app",
        "site-name": "My Awesome Blog"
    }
}
```
**NOTE:** Site name is currently only used in the git revision messages.
If `app` is an empty string the plubish process will create a new Heroku app for you.

Usage
-----
1. To deploy your files to Heroku run the following command from the ruhoh site's root directory:
```
bundle exec ruhoh publish heroku
```