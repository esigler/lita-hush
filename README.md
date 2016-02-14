# lita-hush

[![Build Status](https://img.shields.io/travis/esigler/lita-hush/master.svg)](https://travis-ci.org/esigler/lita-hush)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://tldrlegal.com/license/mit-license)
[![RubyGems](http://img.shields.io/gem/v/lita-hush.svg)](https://rubygems.org/gems/lita-hush)
[![Coveralls Coverage](https://img.shields.io/coveralls/esigler/lita-hush/master.svg)](https://coveralls.io/r/esigler/lita-hush)
[![Code Climate](https://img.shields.io/codeclimate/github/esigler/lita-hush.svg)](https://codeclimate.com/github/esigler/lita-hush)
[![Gemnasium](https://img.shields.io/gemnasium/esigler/lita-hush.svg)](https://gemnasium.com/esigler/lita-hush)

A room moderation plugin for Lita.

## Installation

Add lita-hush to your Lita instance's Gemfile:

``` ruby
gem 'lita-hush'
```

## Configuration

There are no Lita configuration file entries needed.

## Usage

### Example

```
@alice in quiet_room> Lita room add @alice
@alice in quiet_room> Lita room moderation on
@Lita in quiet_room> Room now moderated
@alice in quiet_room> Peace and quiet!
@bob in quiet_room> Hello world!
@Lita PM to @bob> quiet_room is a moderated room
```

### Adding / Removing Someone

```
room add @user
room remove @user
```

### Moderating / Unmoderating a Room

```
room moderation on # Automatically adds requestor to approved list
room moderation off
```

### Status

```
room status
```
