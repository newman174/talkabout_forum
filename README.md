# TalkAbout

## Welcome

Thanks for checking out **TalkAbout**, a simple discussion forum where users may post topics and associated replies.

## Quick Start

1. Install Ruby dependencies using [bundler](https://rubygems.org/gems/bundler):
   - `bundle install`
   - Note: [PostgreSQL](https://www.postgresql.org) must already be installed, otherwise installing the `pg` gem should fail.
2. Create and populate the database:
   - `bundle exec rake resetdb`
3. Start the application:
   - `bundle exec ruby app.rb`
   - This will use the default port of `4567` (you can specify a different port using the argument `-p 1234`).
4. Open the app in your browser: [TalkAbout](http://localhost:4567/)
   - [Sign in](http://localhost:4567/signin) as an existing user:
     - Username: `hamachi` | Password: `brownies`
   - Or [register](http://localhost:4567/register) a new account.

## About

### Features

- Create, read, update, and delete topics and replies:
  - Topics are ordered by latest activity
  - Replies are ordered chronologically
  - Click on a username link to see posts by that user
  - Pagination with variable items per page
  - Markdown support for displaying topics and replies

- Authentication and authorization:
  - Hashed passwords
  - Editing and deleting actions are only available to the user that created the content.
  - Encrypted session cookies (via [encrypted_cookie](https://github.com/cvonkleist/encrypted_cookie)) to (hopefully) prevent tampering.

- Basic search

### Avenues for further development

- Image upload support
- Improved search
- Markdown preview for user content
- Keep a record of when content is edited or deleted
- Browser-based admin powers
- Refactor database_persistence into separate subclasses to make it more digestible
- Store encryption keys and other configuration items in environment variables

### Versions

- Ruby: 2.7.6
- Database: `psql (PostgreSQL) 14.3`
- jQuery JavaScript Library v3.6.0
- Tested on browsers:
  - Google Chrome Version 102.0.5005.115 (Official Build) (arm64)
  - Safari Version 15.5 (17613.2.7.1.8)

### Attribution

- Favicons were generated using [favicon.io](https://favicon.io/).
- Sample data was generated using [faker-ruby](https://github.com/faker-ruby/faker).
- CSS Reset: Tantek Celik's Whitespace Reset
