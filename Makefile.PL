# This file is part of NMS::Rancid::RESTClient Perl module.

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'NMS::Rancid::RESTClient',
	VERSION_FROM    => 'lib/NMS/Rancid/RESTClient.pm',

	PREREQ_PM => {
		LWP::UserAgent => 0,
		HTTP::Request => 0,
		JSON::XS => 0,
	},

	dist => {
		COMPRESS => 'gzip',
		SUFFIX => '.gz',
	},
);