maintainer       "Clearscale"
maintainer_email "support@clearscale.net"
description      "Different tools for Netpulse"

version          "0.0.1"

supports "centos"
supports "redhat"
supports "ubuntu"

attribute "np_tools/short_hostname",
  :display_name => "Short Hostname",
  :description =>
    "The short hostname that you would like this node to have." +
    " Example: myhost",
  :required => "required",
  :recipes => [
    "np_tools::setup_hostname_from_tags"
  ]

attribute "np_tools/domain_name",
  :display_name => "Domain Name",
  :description =>
    "The domain name that you would like this node to have." +
    " Example: example.com",
  :required => "optional",
  :default => "",
  :recipes => [
    "np_tools::setup_hostname"
  ]

attribute "np_tools/search_suffix",
  :display_name => "Domain Search Suffix",
  :description =>
    "The domain search suffix you would like this node to have." +
    " Example: example.com",
  :required => "optional",
  :default => "",
  :recipes => [
    "np_tools::setup_hostname"
  ]

