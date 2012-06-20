# REST client for Rancid web service

package NMS::Rancid::RESTClient;

use strict;
use warnings;

our $VERSION = '0.10';

use LWP::UserAgent;
use HTTP::Request;
use JSON::XS;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    my $self = {};
    $self->{prefix} = $args{prefix} || 'http://localhost:10680';
    $self->{secret} = $args{secret} || undef;
    $self->{debug}  = $args{debug}  || 0;

    bless $self, $class;
    $self->_init;
    return $self;
}

sub setSecret {
    my $self = shift;
    $self->{secret} = shift || undef;
    $self->_setAuthHeader;
}

sub getAllGroups {
    my $self = shift;
    my $method = 'GET';
    my $uri = '/rancid/group/';

    my $response = $self->_run($uri, $method);
    my $groups = $response->{data};
    return $groups;
}

sub getGroup {
    my $self = shift;
    my $name = shift;
    my $method = 'GET';
    my $uri = '/rancid/group/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    my $response = $self->_run($uri.$name, $method);
    my $group = $response->{data};
    return $group;
}

sub addGroup {
    my $self = shift;
    my $name = shift;
    my $method = 'POST';
    my $uri = '/rancid/group/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    my $post_data = { name => $name };

    my $response = $self->_run($uri, $method, $post_data);
    my $group = $response->{data};
    return $group;
}

sub delGroup {
    my $self = shift;
    my $name = shift;
    my $method = 'DELETE';
    my $uri = '/rancid/group/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    my $response = $self->_run($uri.$name, $method);
    return 1;
}

sub getAllNodes {
    my $self = shift;
    my $group_name = shift || undef;
    my $method = 'GET';
    my $uri = '/rancid/node/';

    if (defined $group_name && $group_name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    $uri = '/rancid/group/'.$group_name.'/node/' if (defined $group_name);

    my $response = $self->_run($uri, $method);
    my $nodes = $response->{data};
    return $nodes;
}

sub getNode {
    my $self = shift;
    my $name = shift;
    my $group_name = shift || undef;
    my $method = 'GET';
    my $uri = '/rancid/node/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }
    if (defined $group_name && $group_name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    $uri = '/rancid/group/'.$group_name.'/node/' if (defined $group_name);

    my $response = $self->_run($uri.$name, $method);
    my $nodes = $response->{data};
    return $nodes;
}

sub addNode {
    my $self = shift;
    my $group_name = shift;
    my $data = shift;
    my $method = 'POST';
    my $uri = '/rancid/group/';

    if (!defined $group_name || $group_name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    $uri = $uri.$group_name.'/node/';

    my $response = $self->_run($uri, $method, $data);
    my $node = $response->{data};
    return $node;
}

sub modifyNode {
    my $self = shift;
    my $name = shift;
    my $data = shift;
    my $method = 'POST';
    my $uri = '/rancid/node/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid node name";
    }

    $uri = $uri.$name;

    my $response = $self->_run($uri, $method, $data);
    my $node = $response->{data};
    return $node;
}

sub delNode {
    my $self = shift;
    my $group_name = shift;
    my $name = shift;
    my $method = 'DELETE';
    my $uri = '/rancid/group/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid node name";
    }
    if (!defined $group_name || $group_name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid group name";
    }

    $uri = $uri.$group_name.'/node/'.$name;

    my $response = $self->_run($uri, $method);
    return 1;
}

sub getNodeConfig {
    my $self = shift;
    my $name = shift;
    my $method = 'GET';
    my $uri = '/rancid/node/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid node name";
    }

    $uri = $uri.$name.'/config/';

    my $response = $self->_run($uri, $method);
    my $config = $response->{data};
    return $config;
}

sub addNodeConfig {
    my $self = shift;
    my $name = shift;
    my $data = shift;
    my $method = 'POST';
    my $uri = '/rancid/node/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid node name";
    }
    die "Missing text parameter" if (!defined $data->{text});

    $uri = $uri.$name.'/config/';

    my $response = $self->_run($uri, $method, $data);
    # return diff if any
    return '' if (!defined $response->{data});
    return $response->{data};
}

sub saveNodeConfig {
    my $self = shift;
    my $name = shift;
    my $method = 'GET';
    my $uri = '/rancid/node/';

    if (!defined $name || $name !~ /^[a-zA-Z0-9\-_]+$/) {
        die "Invalid node name";
    }

    $uri = $uri.$name.'/config/save/';

    # this can take some time - increase timeout
    my $timeout_orig = $self->{conn}->timeout();
    $self->{conn}->timeout(120);

    my $response = $self->_run($uri, $method);

    $self->{conn}->timeout($timeout_orig);

    # return diff if any
    return '' if (!defined $response->{data});
    return $response->{data};
}

sub exportCloginrc {
    my $self = shift;
    my $method = 'GET';
    my $uri = '/rancid/cloginrc/export/';

    $self->_run($uri, $method);
}


sub _init {
    my $self = shift;
    my $conn = LWP::UserAgent->new;
    $conn->timeout(10);
    $self->{conn} = $conn;
    $self->_setAuthHeader;
}

sub _setAuthHeader {
    my $self = shift;
    if (defined $self->{secret}) {
        $self->{conn}->default_header('Auth-Secret' => $self->{secret});
    }
}

sub _run {
    my $self = shift;
    my $uri = shift;
    my $method = shift || 'GET';
    my $post_data = shift || undef;
    my ($response, $content, $result);

    if (!defined $self->{conn}) {
        $self->_init();
    }

    if ($method eq 'GET') {
        $response = $self->{conn}->get($self->{prefix}.$uri);
    }
    elsif ($method eq 'POST') {
        if (defined $post_data) {
            $response = $self->{conn}->post($self->{prefix}.$uri, $post_data);
        }
        else {
            $response = $self->{conn}->post($self->{prefix}.$uri);
        }
    }
    elsif ($method eq 'DELETE') {
        my $request =  HTTP::Request->new( DELETE => $self->{prefix}.$uri );
        $response = $self->{conn}->request($request);
    }
    else {
        die "Method not supported";
    }

    if ($response->is_success) {
        $content = $response->decoded_content;
        $result = decode_json $content;
        if (! $result->{success}) {
            die $result->{message};
        }
        return $result;
    }
    else {
        die $response->status_line;
    }
}

1;