#!/usr/bin/perl -I. -w
use strict;

use Test::More tests => 4;

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
	my $class = shift;
	return @_;
}

use Class::DBI::Plugin::AbstractCount;
my ( @bind_params ) = __PACKAGE__->count_search_where(
	{ artist => 'Frank Zappa'
	} );
ok( $main::sql eq "SELECT COUNT(*)\nFROM __TABLE__\nWHERE ( artist = ? )\n"
  , 'sql statement 1'
  );
ok( eq_array( \@bind_params, [ 'Frank Zappa' ] ), 'bind param list 1' );
( @bind_params ) = __PACKAGE__->count_search_where(
	{ artist  => 'Frank Zappa'
	, title   => { like => '%Shut Up \'n Play Yer Guitar%' }
	, release => { between => [ 1980, 1982 ] }
	} );
ok( $main::sql eq "SELECT COUNT(*)\nFROM __TABLE__\nWHERE ( artist = ? AND release BETWEEN ? AND ? AND title like ? )\n"
  , 'sql statement 2'
  );
ok( eq_array( \@bind_params, [ 'Frank Zappa', 1980, 1982, '%Shut Up \'n Play Yer Guitar%' ] ), 'bind param list 2' );

__END__
