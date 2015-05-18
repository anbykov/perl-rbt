#!/usr/bin/perl -w
# The script becomes a demon after the first run.
# This daemon executes the specified command (reboot) after the lapse of the specified time ($intDelay, in seconds).
# If at this time the script is started again, the daemon will be stopped and the command is canceled.

use strict;
use POSIX;
my $strPidPath;
my $intDelay;
my $strCommand;

# Pid file path
$strPidPath = '/var/run/rbt.pid';

# Delay for command execution
$intDelay = 40;

# Command to run
$strCommand = 'reboot';

my $intPid;
my $intForkedPid;
my $boolIsExit;
$boolIsExit = 0;
my $intTimer;
$intTimer = 0;

if (-e $strPidPath ) {
    print "rbt stopped\n";
    open (PIDFILE, "$strPidPath") or die "Can't open PID file $strPidPath\n";
    $intPid = <PIDFILE>;
    chomp $intPid;
    kill 9 => $intPid;
    unlink $strPidPath;
    
} else {
    $intForkedPid = fork;
    if ($intForkedPid) {
        exit;
    };
    die "Can't fork: $!\n" unless defined ($intForkedPid);
    
    # Detach from control terminal
    POSIX::setsid() or die "Can't start new session: $!\n";
    
    # Write pid file
    open (PIDFILE, "> $strPidPath") or die "Cant open PID file $strPidPath, exit\n";
    print PIDFILE $$;
    close PIDFILE;
    
    # Catch sigs
    $SIG{INT} = $SIG{TERM} = $SIG{HUP} = \&funcCatchSig;
    
    print "$strCommand will run after $intDelay seconds.\n";
    $intTimer = time();
    
    while ($boolIsExit == 0) {
        if ((time() - $intTimer) >= $intDelay) {
            system ($strCommand);
	    unlink ($strPidPath);
	    exit;        
        };
        sleep 1;
    };
};

sub funcCatchSig {
    $boolIsExit = 1;
};