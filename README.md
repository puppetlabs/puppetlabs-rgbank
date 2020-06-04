#### Table of Contents

1. [Overview](#overview)
    * [Notice](#notice)
2. [Setup](#setup)
    * [Prerequisites](#prerequisites)
3. [Usage](#usage)

## Overview

The purpose of the `puppet-rgbank` module is to install all application components and setup a working copy of the RGBank application

### Notice
>
> _THIS IS AN EXAMPLE APPLICATION ORCHESTRATION MODULE - NOT INTENDED FOR PRODUCTION USE_
>

## Setup
###Prerequisites
While this module can be deployed on a single node, or multiple nodes - you must first install some prerequisite software.  This software should be installed/handled in a profile PRIOR to applying the RGBank application components

_Database Node_
  - MySQL

_Web Node(s)_
  - Apache
  - PHP
  - MySQL Client
  - MySQL PHP Bindings

Example of doing this using the `puppetlabs-apache` and `puppetlabs-mysql` modules:

_Database Node_
```puppet
include ::mysql::server
include ::mysql::client
```

_Web Nodes(s)_
```puppet
class {'::apache':
  default_vhost => false,
}
include ::apache::mod::php

include ::mysql::client
class {'::mysql::bindings':
  php_enable => true,
}
```

## Usage
An example declaration of this application in site.pp:

```puppet
rgbank { 'getting-started':
  listen_port => 8010,
  nodes       => {
      Node['appserver1d.example.com'] => [Rgbank::Db[getting-started]],
      Node['appserver1b.example.com'] => [Rgbank::Web[appserver-01_getting-started]],
      Node['appserver1c.example.com'] => [Rgbank::Web[appserver-02_getting-started]],
      Node['appserver1a.example.com'] => [Rgbank::Load[getting-started]],
  },
}
```
