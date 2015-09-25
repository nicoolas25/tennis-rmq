# Tennis::Backend::Rabbit

A RabbitMQ backend for [tennis-jobs][tennis-jobs].

<a target="_blank" href="https://travis-ci.org/nicoolas25/tennis-rmq"><img src="https://travis-ci.org/nicoolas25/tennis-rmq.svg?branch=master" /></a>
<a target="_blank" href="https://codeclimate.com/github/nicoolas25/tennis-rmq"><img src="https://codeclimate.com/github/nicoolas25/tennis-rmq/badges/gpa.svg" /></a>
<a target="_blank" href="https://codeclimate.com/github/nicoolas25/tennis-rmq/coverage"><img src="https://codeclimate.com/github/nicoolas25/tennis-rmq/badges/coverage.svg" /></a>
<a target="_blank" href="https://rubygems.org/gems/tennis-jobs-rmq"><img src="https://badge.fury.io/rb/tennis-jobs-rmq.svg" /></a>

## Usage

Simply configure Tennis with this backend:

``` ruby
AMQP_URL = "redis://localhost:6379"

Tennis.configure do |config|
  config.backend = Tennis::Backend::Rabbit.new(logger: logger, url: AMQP_URL)
end
```

## TODO

- Support the delay option.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


[tennis-jobs]: https://github.com/nicoolas25/tennis
