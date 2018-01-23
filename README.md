# Transmap

A simple library for serializing and deserializing hashes into objects and vice-versa

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'transmap'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install transmap

## Usage

To set up the logger

```ruby
Transmap.configure do |config|
  config.logger = Logger.new(STDOUT)
end
```

How to use the Mappers

for simple mappings

```ruby
class Window
  include Transmap::Mappers
 
  simple_map id: :windowId,
             is_exclusive: :exclusive
 
end

obj = Window.from_hash({windowId: 1, exclusive: true})
obj.id #-> 1
obj.is_exclusive #-> true
obj.to_hash #-> {windowId: 1, exclusive: true}

```

for transformation mappings

```ruby
class Window
  include Transmap::Mappers
 
  transform_map :start_on, :epochStart, 
        to: :datetime_to_epoch, from: :epoch_to_datetime

  def self.epoch_to_datetime(milliseconds)
    Time.at(milliseconds/1000).to_datetime if milliseconds.present?
  end
 
  def self.datetime_to_epoch(datetime)
    datetime.to_i * 1000 if datetime.present?
  end
 
end

obj = Window.from_hash({epochStart: 1516499650000})
obj.start_on #-> Saturday, January 20, 2018 5:54:10 PM GMT-08:00
obj.to_hash #-> {epochStart: 1516499650000}

```


## Development

To execute the tests

```bash
bundle install
rspec
```