#
#
#
#

package InstallUtils;

use Term::ReadPassword;
use IPC::Cmd;

sub execCommand {
	my ( $cmd, @args ) = @_;
	my $command = join( ' ', $cmd, @args );

	my ( $ok, $err, $full_buf, $stdout_buff, $stderr_buff ) = IPC::Cmd::run( command => $command, verbose => 1 );

	my $result = 0;
	if ( !$ok ) {
		print "ERROR: $command failed\n";
		$result = 1;
	}
	return $result;
}

sub promptUser {
	my ( $promptString, $defaultValue, $noEcho ) = @_;

	if ($defaultValue) {
		print $promptString, " [", $defaultValue, "]:  ";
	}
	else {
		print $promptString, ":  ";
	}

	if ( defined $noEcho && $noEcho ) {
		my $response = read_password('');
		if ( ( !defined $response || $response eq '' ) && ( defined $defaultValue && $defaultValue ne '' ) ) {
			$response = $defaultValue;
		}
		return $response;
	}
	else {
		$| = 1;
		$_ = <STDIN>;
		chomp;

		if ("$defaultValue") {
			return $_ ? $_ : $defaultValue;
		}
		else {
			return $_;
		}
		return $_;
	}
}

sub trim {
	my $str = shift;

	$str =~ s/^\s+//;
	$str =~ s/^\s+$//;

	return $str;
}

1;
