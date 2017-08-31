source ENV['GEM_SOURCE'] || 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['< 5.0']

gem CFPropertyList,         2.3.5
gem addressable,            2.5.2
gem ast,                    2.3.0
gem aws-sdk-core,           2.10.34
gem aws-sigv4,              1.0.1
gem bundler,                1.14.6
gem diff-lcs,               1.3
gem facter,                 2.5.1
gem faraday,                0.9.2
gem faraday_middleware,     0.10.1
gem fast_gettext,           1.1.0
gem gettext,                3.2.4
gem gettext-setup,          0.26
gem hiera,                  3.4.0
gem hiera-eyaml,            2.1.0
gem highline,               1.6.21
gem jmespath,               1.3.1
gem json-schema,            2.8.0
gem json_pure,              1.8.6
gem librarian-puppet,       2.2.3
gem librarianp,             0.6.3
gem locale,                 2.1.2
gem metaclass,              0.0.4
gem metadata-json-lint,     2.0.2
gem minitar,                0.6.1
gem mocha,                  1.3.0
gem multipart-post,         2.0.0
gem parallel,               1.12.0
gem parser,                 2.4.0.0
gem powerpack,              0.1.1
gem public_suffix,          3.0.0
gem puppet,                 puppetversion
gem puppet-lint,            2.3.0
gem puppet-syntax,          2.4.1
gem puppet_forge,           2.2.7
gem puppetlabs_spec_helper, 2.3.1
gem rainbow,                2.2.2
gem rake,                   12.0.0
gem retries,                0.0.5
gem rspec,                  3.6.0
gem rspec-core,             3.6.0
gem rspec-expectations,     3.6.0
gem rspec-mocks,            3.6.0
gem rspec-puppet,           2.6.8
gem rspec-puppet-utils,     3.4.0
gem rspec-support,          3.6.0
gem rsync,                  1.0.9
gem rubocop,                0.49.1
gem ruby-progressbar,       1.8.1
gem semantic_puppet,        1.0.1
gem spdx-licenses,          1.1.0
gem text,                   1.3.1
gem thor,                   0.20.0
gem trollop,                2.1.2
gem unicode-display_width,  1.3.0

# rspec must be v2 for ruby 1.8.7
if RUBY_VERSION >= '1.8.7' && RUBY_VERSION < '1.9'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 2.0'
else
  # rubocop requires ruby >= 1.9
  gem 'rubocop'
end
