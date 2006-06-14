#!/usr/bin/perl -I. -w
# vim:set tabstop=2 shiftwidth=2 expandtab syn=perl:
use strict;

use Test::More tests => 20;

$main::sql = "";

sub set_sql
{
  my ( $class, $name, $sql ) = @_;
  no strict 'refs';
  *{ "$class\::sql_$name" } =
    sub
    {
      my ( $class, $where ) = @_;
      ( $main::sql = sprintf $sql, $where ) =~ s/^\s+//mg;
      return $class;
    };
}

sub retrieve_from_sql {} # Make plugin believe we're inheriting from Class::DBI

sub select_val
{
  shift;
  return @_;
}

sub columns { return qw( artist title release updated ) }

sub _croak
{
  shift;
  die ": _croak(): '@_'\n";
}

# If we can't be free, at least we can be cheap...
{
  package artist;
  sub accessor { return 'artist_name' }
}
{
  package title;
  sub accessor { return 'album_title' }
}
{
  package release;
  sub accessor { return 'release_date' }
}
{
  package updated;
  sub accessor { return 'last_change' }
}

use Class::DBI::Plugin::AbstractCount;

# Test simple where-clause
my ( @bind_params ) = __PACKAGE__->count_search_where(
  { artist => 'Frank Zappa'
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( artist = \? \)\n/i
  , 'sql statement 1'
  );
is_deeply( \@bind_params, [ 'Frank Zappa' ], 'bind param list 1' );

# Test more complex where-clause
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist  => 'Frank Zappa'
  , title   => { like => '%Shut Up \'n Play Yer Guitar%' }
  , release => { between => [ 1980, 1982 ] }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( artist = \? AND release BETWEEN \? AND \? AND title LIKE \? \)\n/i
  , 'sql statement 2'
  );
is_deeply( \@bind_params, [ 'Frank Zappa'
                          , 1980
                          , 1982
                          , '%Shut Up \'n Play Yer Guitar%'
                          ], 'bind param list 2' );

# Test where-clause with accessors
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist_name  => 'Steve Vai'
  , album_title  => { like => 'Flexable%' }
  , release_date => { between => [ 1983, 1984 ] }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( artist = \? AND release BETWEEN \? AND \? AND title LIKE \? \)\n/i
  , 'sql statement 3'
  );
is_deeply( \@bind_params, [ 'Steve Vai'
                          , 1983
                          , 1984
                          , 'Flexable%'
                          ], 'bind param list 3' );

# Test where-clause with simple function-call on column name
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist            => 'Adrian Belew'
  , 'YEAR( release )' => { '=', 2005 }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( YEAR\( release \) = \? AND artist = \? \)\n/i
  , 'sql statement 4'
  );
is_deeply( \@bind_params, [ 2005
                          , 'Adrian Belew'
                          ], 'bind param list 4' );

# Test where-clause with more complicated (nested) function-call on column name
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist            => 'Adrian Belew'
  , 'COALESCE( release, NOW() )' => { '=', 2005 }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( COALESCE\( release, NOW\(\) \) = \? AND artist = \? \)\n/i
  , 'sql statement 5'
  );
is_deeply( \@bind_params, [ 2005
                          , 'Adrian Belew'
                          ], 'bind param list 5' );

# Test where-clause with simple function-call on accessor
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist_name            => 'Adrian Belew'
  , 'YEAR( release_date )' => { '=', 2005 }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( YEAR\( release \) = \? AND artist = \? \)\n/i
  , 'sql statement 6'
  );
is_deeply( \@bind_params, [ 2005
                          , 'Adrian Belew'
                          ], 'bind param list 6' );

# Test where-clause with more complicated (nested) function-call on accessor
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist_name            => 'Adrian Belew'
  , 'COALESCE( release_date, NOW() )' => { '=', 2005 }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( COALESCE\( release, NOW\(\) \) = \? AND artist = \? \)\n/i
  , 'sql statement 7'
  );
is_deeply( \@bind_params, [ 2005
                          , 'Adrian Belew'
                          ], 'bind param list 7' );

# Test where-clause with more complicated (nested) function-call on multiple
# column names
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist            => 'Adrian Belew'
  , 'COALESCE( release, updated, NOW() )' => { '=', 2005 }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( COALESCE\( release, updated, NOW\(\) \) = \? AND artist = \? \)\n/i
  , 'sql statement 8'
  );
is_deeply( \@bind_params, [ 2005
                          , 'Adrian Belew'
                          ], 'bind param list 8' );

# Test where-clause with more complicated (nested) function-call on mixed
# column and accessor names
( @bind_params ) = __PACKAGE__->count_search_where(
  { artist            => 'Adrian Belew'
  , 'COALESCE( release, last_change, NOW() )' => { '=', 2005 }
  } );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( COALESCE\( release, updated, NOW\(\) \) = \? AND artist = \? \)\n/i
  , 'sql statement 9'
  );
is_deeply( \@bind_params, [ 2005
                          , 'Adrian Belew'
                          ], 'bind param list 9' );

# Test complex where-clause
( @bind_params ) = __PACKAGE__->count_search_where(
  -and => [ artist => 'System Of A Down'
          , -nest  => [ -and => [ title   => { like => '%ize' }
                                , release => 2005
                                ]
                      , -and => [ title   => { like => '%ize' }
                                , release => 2006
                                ]
                      ]
          ] );
like( $main::sql, qr/SELECT COUNT\(\*\)\nFROM __TABLE__\nWHERE \( \( \( artist = \? \) AND \( \( \( \( \( title LIKE \? \) AND \( release = \? \) \) \) OR \( \( \( title LIKE \? \) AND \( release = \? \) \) \) \) \) \) \)\n/i
  , 'sql statement 10'
  );
is_deeply( \@bind_params, [ 'System Of A Down'
                          , '%ize'
                          , 2005
                          , '%ize'
                          , 2006
                          ], 'bind param list 10' );
__END__
