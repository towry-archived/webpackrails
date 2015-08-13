# WebpackRails

This gem make [Webpack](http://webpack.github.io) works with [Rails](http://github.com/rails/rails).

## Installation

*Rails: >= 3*

Add this line to your application's Gemfile:

```ruby
gem 'webpackrails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install webpackrails

Create `package.json` in your Rails root:

```json
{
  "name": "app",
  "dependencies": {
    "webpack": "^1.11.0",
    "railshot-webpack-plugin": "*"
  }
}
```

Run `npm i` to install the dependencies.

## Usage

Make sure you have a `webpack.config.js` file in your Rails root dir, or specific your
webpack config file within `application.rb`

`config.webpackrails.config_file = "path_to_the_config_file"`

#### Watch file for changes

Use webpack plugin `railshot-webpack-plugin` in your `webpack.config.js`.
If you haven't install the plugin yet, run `npm install railshot-webpack-plugin`.

```js
// webpack.config.js

var railshotPlugin = require('railshot-webpack-plugin');

// no entry here.
module.exports = {
  plugins: [
    railshotPlugin()
  ]
}
```

#### Troubleshooting

[Wiki troubleshooting](https://github.com/towry/webpackrails/wiki/Troubleshooting)

### Config

See [source](https://raw.githubusercontent.com/towry/webpackrails/master/lib/webpackrails/railtie.rb)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/towry/webpackrails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

