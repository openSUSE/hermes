package Hermes::Cache;

#memcache module doc: http://search.cpan.org/~kroki/Cache-Memcached-Fast-0.12/lib/Cache/Memcached/Fast.pm

# Caching for Hermes data

use strict;
use Cache::Memcached::Fast;
use Data::Dumper;
use Hermes::Log;

use constant EXPIRE_IN_SECONDS => 60;

our $self;


#----------------------------------------------------
# new()
#----------------------------------------------------
# Initiates connection to the memcache server

sub new
{
    my $class = shift;
    my $self = {};
    bless( $self, $class );
    
    $self->{memd} = new Cache::Memcached::Fast({
        servers => [ { address => 'localhost:11211'} ],
        namespace => 'hermes:',
        connect_timeout => 0.2,
        io_timeout => 0.5,
        close_on_error => 0,
        compress_threshold => 100_000,
        compress_ratio => 0.9,
        max_failures => 3,
        failure_timeout => 2,
        ketama_points => 150,
        hash_namespace => 1,
        serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
        utf8 => ($^V ge v5.8.1 ? 1 : 0),
        max_size => 512 * 1024,
    });

    log( 'debug', "Memcached connection established." );

    return $self;
}


# adding a document. 
sub put {
    my ( $self, $key, $data ) = @_;

    $self->{memd}->set($key, $data, EXPIRE_IN_SECONDS);
}


# get a document
sub get {
    my ( $self, $key) = @_;
    
    my $val = $self->{memd}->get( $key );
    return $val;
}

sub invalidate {
    my ($self) = @_;
    
    $self->{memd}->flush_all;

}

1;

