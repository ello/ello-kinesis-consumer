<img src="http://d324imu86q1bqn.cloudfront.net/uploads/user/avatar/641/large_Ello.1000x1000.png" width="200px" height="200px" />

# Ello Kinesis Consumer

[![Build Status](https://travis-ci.org/ello/ello-kinesis-consumer.svg?branch=master)](https://travis-ci.org/ello/ello-kinesis-consumer)
[![Code Climate](https://codeclimate.com/github/ello/ello-kinesis-consumer/badges/gpa.svg)](https://codeclimate.com/github/ello/ello-kinesis-consumer)
[![Security](https://hakiri.io/github/ello/ello-kinesis-consumer/master.svg)](https://hakiri.io/github/ello/ello-kinesis-consumer/master)

This is a deployable app that consumes domain events from Kinesis to syndicate
data out to several third-party integrations.

Currently, it integrates with Mailchimp (for newsletter management) and
Knowtify (for drip campaigns).

## Setup

This project uses [dotenv](https://github.com/bkeepers/dotenv) to
manage application configuration in development.  To get started, you
need to `cp .env.example .env` to setup the local development
environment variables.

You'll also need a working Ruby 2.3 setup with bundler

Once those are set up, you can run the tests with `rake`.

## License
Ello Notifications is released under the [MIT License](blob/master/LICENSE.txt)

## Code of Conduct
Ello was created by idealists who believe that the essential nature of all human beings is to be kind, considerate, helpful, intelligent, responsible, and respectful of others. To that end, we will be enforcing [the Ello rules](https://ello.co/wtf/policies/rules/) within all of our open source projects. If you don’t follow the rules, you risk being ignored, banned, or reported for abuse.
