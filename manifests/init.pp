# Class: awsiac
# ===========================
class awsiac (
  $cidr_block  = $::cidr_block,
  $ensure      = $::ensure,
  $instances   = {},
  $region      = $::region,
  $vpc_prefix  = $::vpc_prefix,
  $zone        = undef,
  ){
  # Reverse the default resource ordering if the resources are to be 'absent'.
  if $ensure == 'absent' {
    Route53_a_record <| |> -> Ec2_instance <| |>
    Ec2_instance <| |> -> Ec2_securitygroup <| |>
    Ec2_instance <| |> -> Ec2_vpc_subnet <| |>
    Ec2_securitygroup <| |> -> Ec2_vpc <| |>
    Ec2_vpc_subnet <| |> -> Ec2_vpc <| |>
    Ec2_vpc_subnet <| |> -> Ec2_vpc_internet_gateway <| |>
    Ec2_vpc_subnet <| |> -> Ec2_vpc_routetable <| |>
    Ec2_vpc_internet_gateway <| |> -> Ec2_vpc <| |>
    Ec2_vpc_routetable <| |> -> Ec2_vpc <| |>
    Ec2_vpc <| |> -> Ec2_vpc_dhcp_options <| |>
  }

  case $region {
      'eu-west-1': { $az_list = ['a', 'b', 'c'] }
      default: {
        $az_list = ['a', 'b']
        warning("Assuming that region ${region} has 2 AZs.")
      }
  }

  $regsubst_target = upcase("${vpc_prefix}${region}")
  $regsubst_regexp = "-([A-Z]).*(\\d+)$"
  $vpc = regsubst($regsubst_target, $regsubst_regexp, '\1\2\3', 'I')
  $first2octets = regsubst($cidr_block,'^(\d+)\.(\d+)\.(\d+)\.(\d+)/(\d+)$','\1.\2')
  $metadata = load_module_metadata('awsiac')

  $subnet_cidr_blocks = {
    'web' => {
      'a'     => "${first2octets}.0.0/24",
      'b'     => "${first2octets}.1.0/24",
      'c'     => "${first2octets}.2.0/24",
      'names' => [
        "${vpc}-web1a-sbt",
        "${vpc}-web1b-sbt",
        "${vpc}-web1c-sbt"
      ]
    },
    'app' => {
      'a'     => "${first2octets}.3.0/24",
      'b'     => "${first2octets}.4.0/24",
      'c'     => "${first2octets}.5.0/24",
      'names' => [
        "${vpc}-app1a-sbt",
        "${vpc}-app1b-sbt",
        "${vpc}-app1c-sbt"
      ]
    },
    'db'  => {
      'a'     => "${first2octets}.6.0/24",
      'b'     => "${first2octets}.7.0/24",
      'c'     => "${first2octets}.8.0/24",
      'names' => [
        "${vpc}-db1a-sbt",
        "${vpc}-db1b-sbt",
        "${vpc}-db1c-sbt"
      ]
    }
  }

  $tags = {
    environment => downcase($vpc),
    version     => $metadata['version']
  }

  if $zone {
    ec2_vpc_dhcp_options { "${vpc}-dopt":
      ensure              => $ensure,
      domain_name         => $zone,
      domain_name_servers => 'AmazonProvidedDNS',
      region              => $region,
      tags                => $tags,
    }
    ec2_vpc { $vpc:
      ensure       => $ensure,
      cidr_block   => $cidr_block,
      dhcp_options => "${vpc}-dopt",
      region       => $region,
      tags         => $tags,
    }
  } else {
    ec2_vpc { $vpc:
      ensure     => $ensure,
      cidr_block => $cidr_block,
      region     => $region,
      tags       => $tags,
    }
  }

  ec2_vpc_internet_gateway { "${vpc}-igw":
    ensure => $ensure,
    region => $region,
    vpc    => $vpc,
    tags   => $tags,
  }

  ec2_vpc_routetable { "${vpc}-rtb":
    ensure => $ensure,
    region => $region,
    vpc    => $vpc,
    tags   => $tags,
    routes => [
      {
        destination_cidr_block => $cidr_block,
        gateway                => 'local'
      },{
        destination_cidr_block => '0.0.0.0/0',
        gateway                => "${vpc}-igw"
      },
    ],
  }

  ['web', 'app', 'db'].each | String $tier | {
    $az_list.each | String $az | {
      ec2_vpc_subnet { "${vpc}-${tier}1${az}-sbt":
        ensure                  => $ensure,
        region                  => $region,
        cidr_block              => $subnet_cidr_blocks[$tier][$az],
        availability_zone       => "${region}${az}",
        map_public_ip_on_launch => true,
        route_table             => "${vpc}-rtb",
        vpc                     => $vpc,
        tags                    => $tags,
      }
    }
  }

  case count($az_list) {
    2: {
      $subnet_data = {
        'app' => {
          'a'     => $subnet_cidr_blocks['app']['a'],
          'b'     => $subnet_cidr_blocks['app']['b'],
          'names' => [
            $subnet_cidr_blocks['app']['names'][0],
            $subnet_cidr_blocks['app']['names'][1]
          ]
        },
        'db'  => {
          'a'     => $subnet_cidr_blocks['db']['a'],
          'b'     => $subnet_cidr_blocks['db']['b'],
          'names' => [
            $subnet_cidr_blocks['db']['names'][0],
            $subnet_cidr_blocks['db']['names'][1]
          ]
        },
        'web' => {
          'a'     => $subnet_cidr_blocks['web']['a'],
          'b'     => $subnet_cidr_blocks['web']['b'],
          'names' => [
            $subnet_cidr_blocks['web']['names'][0],
            $subnet_cidr_blocks['web']['names'][1]
          ]
        }
      }
    }
    3: {
      $subnet_data = $subnet_cidr_blocks
    }
    default: {
      fail('Unsupported number of availability zones')
    }
  }

  ec2_securitygroup { "${vpc}-www-sg":
    ensure      => $ensure,
    region      => $region,
    vpc         => $vpc,
    description => 'Security group for the www role',
    ingress     => [
      {
        protocol => 'tcp',
        port     => 22,
        cidr     => '0.0.0.0/0',
      }, {
        protocol => 'tcp',
        port     => 80,
        cidr     => '0.0.0.0/0',
      }, {
        protocol => 'tcp',
        port     => 443,
        cidr     => '0.0.0.0/0',
      }
    ],
    tags        => $tags,
  }

  $instances.keys().each | String $role | {
    range('1', $instances[$role]['number_of_instances']).each | Integer $n | {
      if $zone {
        $instance_name = downcase("${vpc}-${role}${n}.${zone}")
      } else {
        $instance_name = downcase("${vpc}-${role}${n}")
      }

      if $ensure == 'absent' {
        $instance_ensure = 'absent'
      } else {
        $instance_ensure = $instances[$role]['ensure']
      }

      if $instance_ensure == 'absent' {
        $ip = generate('/bin/bash', '-c', 'host d1euw2-www1.locp.co.uk. | awk "{ print \$NF }"')

        route53_a_record { "${instance_name}.":
          ensure => absent,
          ttl    => '3600',
          values => [ $ip ],
          zone   => "${zone}.",
        }
      }

      ec2_instance { $instance_name:
        ensure                    => $instance_ensure,
        region                    => $region,
        availability_zone         => "${region}${az_list[ $n % count($az_list) - 1 ]}",
        iam_instance_profile_name => 'puppet',
        image_id                  => $instances[$role]['image_id'],
        instance_type             => $instances[$role]['instance_type'],
        key_name                  => 'puppet',
        subnet                    => $subnet_data[$instances[$role]['tier']]['names'][$n % count($az_list) - 1],
        security_groups           => [ "${vpc}-${role}-sg"],
        tags                      => merge($tags, { 'role' => $role }),
        user_data                 => template("awsiac/${environment}/${role}/userdata.erb"),
      }
    }
  }
}
