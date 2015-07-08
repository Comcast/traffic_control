package Fixtures::Type;
#
# Copyright 2015 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
use Moose;
extends 'DBIx::Class::EasyFixture';
use namespace::autoclean;
use Digest::SHA1 qw(sha1_hex);

my %definition_for = (
	EDGE => {
		new   => 'Type',
		using => {
			id           => 1,
			name         => 'EDGE',
			description  => 'Edge Cache',
			use_in_table => 'server',
		},
	},
	MID => {
		new   => 'Type',
		using => {
			id           => 2,
			name         => 'MID',
			description  => 'Mid Tier Cache',
			use_in_table => 'server',
		},
	},
	ORG => {
		new   => 'Type',
		using => {
			id           => 3,
			name         => 'ORG',
			description  => 'Origin',
			use_in_table => 'server',
		},
	},
	CCR => {
		new   => 'Type',
		using => {
			id           => 4,
			name         => 'CCR',
			description  => 'Kabletown Content Router',
			use_in_table => 'server',
		},
	},
	EDGE_LOC => {
		new   => 'Type',
		using => {
			id           => 5,
			name         => 'EDGE_LOC',
			description  => 'Edge Cachegroup',
			use_in_table => 'cachegroup',
		},
	},
	MID_LOC => {
		new   => 'Type',
		using => {
			id           => 6,
			name         => 'MID_LOC',
			description  => 'Mid Cachegroup',
			use_in_table => 'deliveryservice',
		},
	},
	DNS => {
		new   => 'Type',
		using => {
			id           => 7,
			name         => 'DNS',
			description  => 'DNS Content Routing',
			use_in_table => 'deliveryservice',
		},
	},
	OTHER_CDN => {
		new   => 'Type',
		using => {
			id           => 8,
			name         => 'OTHER_CDN',
			description  => 'Other CDN (CDS-IS, Akamai, etc)',
			use_in_table => 'server',
		},
	},
	HTTP_NO_CACHE => {
		new   => 'Type',
		using => {
			id           => 9,
			name         => 'HTTP_NO_CACHE',
			description  => 'HTTP Content Routing, no caching',
			use_in_table => 'deliveryservice',
		},
	},
	HTTP_LIVE => {
		new   => 'Type',
		using => {
			id           => 11,
			name         => 'HTTP_LIVE',
			description  => 'HTTP Content routing cache in RAM ',
			use_in_table => 'deliveryservice',
		},
	},
	HTTP_LIVE => {
		new   => 'Type',
		using => {
			id           => 12,
			name         => 'HTTP_LIVE',
			description  => 'HTTP Content routing cache in RAM ',
			use_in_table => 'deliveryservice',
		},
	},
	RASCAL => {
		new   => 'Type',
		using => {
			id           => 14,
			name         => 'RASCAL',
			description  => 'Rascal health polling & reporting',
			use_in_table => 'server',
		},
	},
	HOST_REGEXP => {
		new   => 'Type',
		using => {
			id           => 19,
			name         => 'HOST_REGEXP',
			description  => 'Host header regular expression',
			use_in_table => 'regex',
		},
	},
	PATH_REGEXP => {
		new   => 'Type',
		using => {
			id           => 20,
			name         => 'PATH_REGEXP',
			description  => 'Path regular expression',
			use_in_table => 'regex',
		},
	},
	A_RECORD => {
		new   => 'Type',
		using => {
			id           => 21,
			name         => 'A_RECORD',
			description  => 'Static DNS A entry',
			use_in_table => 'staticdnsentry',
		}
	},
	AAAA_RECORD => {
		new   => 'Type',
		using => {
			id           => 22,
			name         => 'AAAA_RECORD',
			description  => 'Static DNS AAAA entry',
			use_in_table => 'staticdnsentry',
		}
	},
	CNAME_RECORD => {
		new   => 'Type',
		using => {
			id           => 23,
			name         => 'CNAME_RECORD',
			description  => 'Static DNS CNAME entry',
			use_in_table => 'staticdnsentry',
		}
	},
	HTTP_LIVE_NATNL => {
		new   => 'Type',
		using => {
			id           => 24,
			name         => 'HTTP_LIVE_NATNL',
			description  => 'HTTP Content routing, RAM cache, National',
			use_in_table => 'deliveryservice',
		}
	},
	REDIS => {
		new   => 'Type',
		using => {
			id           => 25,
			name         => 'REDIS',
			description  => 'Redis stats gateway',
			use_in_table => 'server',
		}
	},
	DNS_LIVE_NATNL => {
		new   => 'Type',
		using => {
			id           => 26,
			name         => 'DNS_LIVE_NATNL',
			description  => 'DNS Content routing, RAM cache, National',
			use_in_table => 'deliveryservice',
		}
	},
	DNS_LIVE_NATNL => {
		new   => 'Type',
		using => {
			id           => 27,
			name         => 'DNS_LIVE_NATNL',
			description  => 'DNS Content routing, RAM cache, National',
			use_in_table => 'deliveryservice',
		}
	},
	LOCAL => {
		new   => 'Type',
		using => {
			id           => 28,
			name         => 'LOCAL',
			description  => 'Local User',
			use_in_table => 'tm_user',
		}
	},
	ACTIVE_DIRECTORY => {
		new   => 'Type',
		using => {
			id           => 29,
			name         => 'ACTIVE_DIRECTORY',
			description  => 'Active Directory User',
			use_in_table => 'tm_user',
		}
	},
	TOOLS_SERVER => {
		new   => 'Type',
		using => {
			id           => 30,
			name         => 'TOOLS_SERVER',
			description  => 'Ops hosts for management',
			use_in_table => 'server',
		}
	},
	RIAK => {
		new   => 'Type',
		using => {
			id           => 31,
			name         => 'RIAK',
			description  => 'riak type',
			use_in_table => 'server',
		}
	},
	INFLUXDB => {
		new   => 'Type',
		using => {
			id           => 32,
			name         => 'INFLUXDB',
			description  => 'influxdb type',
			use_in_table => 'server',
		}
	},

);

sub get_definition {
	my ( $self, $name ) = @_;
	return $definition_for{$name};
}

sub all_fixture_names {
	return keys %definition_for;
}

__PACKAGE__->meta->make_immutable;

1;
