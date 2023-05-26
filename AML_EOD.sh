#!/bin/bash

###################################################
#
# AML - Ingestion Script automatically ingest batch for date provided - Master Shell Trigger 
# Files generated from UBS: Account , AccountAddress , AccountEmailAddress , AccountBalance , AccountToCorrespondent , AccountPhone , AccountToCustomer , AnticipatoryProfile , BackOfficeTransaction , ChangeLog , Employee , FrontOfficeTransaction, FrontOfficeTransactionParty 
# Files generated from CRM: Customer , CustomerAddress , CustomerEmailAddress , CustomerPhone 
# SI WatchList files:       WatchList , WatchListEntry
#  
# Created By: Hafiz Asad Ahmed - Techlogix. 16 November 2013
# Updated By: Syed Umair Aziz & Aman Gokrani - Techlogix. 29 September  2015
# Updated BY : Salman Samad 29th Aug 2016 - FBC Scenarios
# Purpose : Add all newly created jobs for 10 Scenarios
# Updated by : Ayesha Khalid 26 October 2016 - to add the replace REM with ORG temporary fix
# Updated By : Muhammad Salman Salman , reason : workflows added in order to generate customer summary 
# Updated for BOP : added escalation in account + commented some task!
# Updated By : Naukhaiz Ejaz on 1st November 2022 - Unified EOD script for daily, weekly and monthly scenarios.
# Updated By : Naukhaiz Ejaz on 15 February 2023 - Activation of DNFBP Scenario.
 																			 
###################################################

clear

MISDATE=$1
TASK_NO=$2

SLEEP_TIME=240
RETRY_COUNT=3
TASK_COUNT=0

# Check MIS should not be empty and in YYYYMMDD format 
if [ -z "$MISDATE" ] || [ ${#MISDATE} -ne 8  ]; then 
echo "Date is either empty or not in correct format, please input MISDATE as YYYYMMDD."
exit 1 
fi

filename=/data/DI_SCRIPTS/DI_Logs/AML_LogFile_"$MISDATE"_DLY_01.log

ExecuteWorkflow ()
{

RETRY=$RETRY_COUNT

while [ $RETRY -ge 1 ]

    do
    
	$BDF_HOME/scripts/execute.sh $2
   
    if [ "$?" != "0" ]; then   
	
	RETRY=`expr $RETRY - 1`
	echo "Task No.$1 Failed and Retry to execute BDF_HOME/scripts/execute.sh $2 on $(date +'%A %d %b %Y %X')" >> "$filename"
	sleep $SLEEP_TIME
	
	else
	
	echo "Task No.$1 Executed BDF_HOME/scripts/execute.sh $2 on $(date +'%A %d %b %Y %X')" >> "$filename"
	break	
	fi
	
	done
	
if [ $RETRY -le 0 ]; then  exit 1 
fi

}

if  [ -f "$filename" ]; then 
       
	 echo ''
 	 echo "############## Remaining jobs resume after getting EOD failure for $MISDATE from TaskNo-$TASK_NO at $(date +'%A %d %b %Y %X') ##############"
	 echo '' >> "$filename"
     echo "############## Remaining jobs resume after getting EOD failure for $MISDATE from TaskNo-$TASK_NO at $(date +'%A %d %b %Y %X') ##############" >> "$filename"
	 echo '' >> "$filename"
	 
	 else
	  
	 echo ''
	 echo "########################## Starting AML data ingestion for MIS Date $MISDATE ##########################"
	 echo "########################## Starting AML data ingestion for MIS Date $MISDATE ##########################" >> "$filename"
	 echo '' >> "$filename"
	 
fi

if  [ "$TASK_NO" = ""  ]; then 
TASK_NO=0
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/set_mantas_date.sh $MISDATE
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/set_mantas_date.sh $MISDATE on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Utililty Spaces
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/run_drm_utility.sh P X MANTAS A N
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_drm_utility.sh P X BUSINESS A N on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Run every Friday

day=${MISDATE#??????}
temp=${MISDATE#????}
month=${temp%??}
year=${MISDATE%????}

DOW=$(cal $month $year | awk '
BEGIN{split("Sun Mon Tue Wed Thu Fri Sat",dow);dow[0]=dow[7]}
NR==3{t=7-NF+MISDATE;print dow[t%7];exit}' MISDATE=$day)

export MISDATE

# Calculate 1st business day of the month

IS_FirstDate=$(perl -e 'use strict;
my $First_day = _calc_first_day();
my $Curr_date = `date +%m/%d/%y`;

if($First_day eq $ENV{MISDATE}){printf "Y";}
else {printf "N";}

sub _calc_first_day {
	use Time::Local;
	use POSIX qw(strftime);

	my $_year = substr $ENV{MISDATE}, 0, 4;
	my $_month = substr $ENV{MISDATE}, 4, 2;
	chomp($_year, $_month);

	# Calculate the first day of the month.
	my $_temp_month = (timelocal(0, 0, 0, 1, $_month - 1, $_year));
	my $_first_day = (localtime($_temp_month))[3];
	
	# Make sure it is a business day.
	my $_day = strftime "%a", localtime($_temp_month);
	if ($_day eq "Sun") { $_first_day++; }
	#if ($_day eq "Fri") { for (1..2) { $_first_day++; } }
    my $_return = sprintf "%d%.2d%.2d", $_year, $_month, $_first_day;
	#print scalar "_return=$_return\n";
    return $_return;
}')

# Calculate week number

Week=$(perl -e 'use strict;
use Time::Local;
use POSIX qw(strftime);

my $day_ = substr $ENV{MISDATE}, 6, 2;
my $month_ = substr $ENV{MISDATE}, 4, 2;
my $year_ = substr $ENV{MISDATE}, 0, 4;

chomp($year_, $month_, $day_);
#printf "Day: %d Month: %d Year: %d \n", $day_, $month_, $year_;

my $epoch = timelocal( 0, 0, 0, $day_, $month_ - 1, $year_ - 1900 );
my $week  = strftime( "%U", localtime( $epoch ) );

chomp($week);
if ($week eq "00") {  $week = $week + 1 ; }
if( $week % 2 eq 0){printf "Y";}
else {printf "N";}
')




# Run every Last Business day of the month

IS_LastDate=$(perl -e 'use strict;
my $last_day = _calc_last_day();

if($last_day eq $ENV{MISDATE}){printf "Y";}
else {printf "N";}

sub _calc_last_day {
	use Time::Local;
	use POSIX qw(strftime);

	my $_year = substr $ENV{MISDATE}, 0, 4;
	my $_month = substr $ENV{MISDATE}, 4, 2;
	chomp($_year, $_month);
	
	# Calculate the last day of the month.
	my $_next_year = ($_month == 12) ? $_year + 1 : $_year;
	my $_next_month = timelocal(0, 0, 0, 1, $_month % 12, $_next_year);
	my $_last_day = (localtime($_next_month - 86400))[3];
	# Make sure it is a business day.
	my $_day = strftime "%a", localtime($_next_month - 86400);
	#print scalar "_day=$_day\n";
	if ($_day eq "Sun") { $_last_day--; }
	#if ($_day eq "Sat") { for (1..2) { $_last_day--; } }

	return "$_year$_month$_last_day";
}')


# Daily Utililty

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/run_drm_utility.sh P D MANTAS A Y
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_drm_utility.sh P D BUSINESS A Y on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


# Weekly Utility

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DB_TOOLS_HOME/bin/run_drm_utility.sh P W MANTAS A N
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_drm_utility.sh P W BUSINESS A N on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac
fi

#Calculating Last Date
IS_LastDate=$(perl -e 'use strict;
my $last_day = _calc_last_day();

if($last_day eq $ENV{MISDATE}){printf "Y";}
else {printf "N";}

sub _calc_last_day {
	use Time::Local;
	use POSIX qw(strftime);

	my $_year = substr $ENV{MISDATE}, 0, 4;
	my $_month = substr $ENV{MISDATE}, 4, 2;
	chomp($_year, $_month);
	
	# Calculate the last day of the month.
	my $_next_year = ($_month == 12) ? $_year + 1 : $_year;
	my $_next_month = timelocal(0, 0, 0, 1, $_month % 12, $_next_year);
	my $_last_day = (localtime($_next_month - 86400))[3];
	# Make sure it is a business day.
	my $_day = strftime "%a", localtime($_next_month - 86400);
	#print scalar "_day=$_day\n";
	if ($_day eq "Fri") { $_last_day--; }
	if ($_day eq "Sat") { for (1..2) { $_last_day--; } }

	return "$_year$_month$_last_day";
}')


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $IS_FirstDate in
"Y")
echo '' >> "$filename"
echo "##### First Bussiness Day Of The Month Activity #####" >> "$filename"
$DB_TOOLS_HOME/bin/run_drm_utility.sh P M MANTAS A N
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_drm_utility.sh P M BUSINESS A N on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/start_mantas_batch.sh DLY
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/start_mantas_batch.sh DLY on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then

echo '' >> "$filename"
 echo '##### BDF MAPS JOBS #####' >> "$filename"
fi
 
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh FrontOfficeTransaction
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh FrontOfficeTransaction on $(date +'%A %d %b %Y %X')" >> "$filename"
fi 


 
#$BDF_HOME/scripts/execute.sh FrontOfficeTransaction
#echo "Task No.$TASK_COUNT Executed BDF_HOME/scripts/execute.sh FrontOfficeTransaction on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh WatchList
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh WatchList on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh Account
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh Account on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh Customer
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh Customer on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



####ADDED BY MUNEEB####

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh LinkedEntity
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh LinkedEntity on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh LinkedEntityInfo
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh LinkedEntityInfo on $(date +'%A %d %b %Y %X')" >> "$filename"
fi




#### ADDED BY MUNEEB####

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh CustomerCountry
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerCountry on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh Employee
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh Employee on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then 
#$BDF_HOME/scripts/execute.sh Employee
#echo "Task No.$TASK_COUNT Executed BDF_HOME/scripts/execute.sh Employee on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh EmployeeToAccount
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh EmployeeToAccount on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then 
#$BDF_HOME/scripts/execute.sh EmployeeToAccount
#echo "Task No.$TASK_COUNT Executed BDF_HOME/scripts/execute.sh EmployeeToAccount on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh FrontOfficeTransactionParty
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh FrontOfficeTransactionParty on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh TrustedPair
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh TrustedPair on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


############################


#############Added by Fazeel ###############
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh Channels
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh Channels on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh Modeoftrans
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh Modeoftrans on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

############################
#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#echo '' >> "$filename"
#echo '##### UPDATE FOTP #####' >> "$filename"
#sqlplus mantas/mantas@172.16.119.79:1521/ofsaa << EOF
#execute mantas.replace_rem_org_cstm_tlx();
#exit;
#EOF
#echo "Task No.$TASK_COUNT Executed Replace REM with ORG Job on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi
#
################################################



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh WatchListEntry 
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh WatchListEntry on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountAddress 
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountAddress on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountBalance 
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountBalance on $(date +'%A %d %b %Y %X')" >> "$filename"
fi
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountToCustomer
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountToCustomer on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh CustomerAddress
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerAddress on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh CustomerEmailAddress
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerEmailAddress on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh CustomerPhone
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerPhone on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



#LOAN data FILES
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh Loan
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerPhone on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh LoanDailyActivity
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerPhone on $(date +'%A %d %b %Y %X')" >> "$filename"
fi




TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh BackOfficeTransaction
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh BackOfficeTransaction on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
response_txt=`sqlplus -s mantas/mantas@OFSAA <<EOF
var r1 varchar2(1);
set head off;
set feedback off; 
--set serverout off; 
exec :r1:=BO_UPDATE_TLX_CSTM_FN();
print r1;
commit;
exit;
EOF` 
response_txt=$(echo $response_txt|tr -d '\n')
echo $response_txt 
if [ "$response_txt" == "1" ]; then  
echo "Successful"
else 
echo "Failed"
fi
echo "Task No.$TASK_COUNT Updated offset account ID in BOT on $(date +'%A %d %b %Y %X')"  >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountCustomerRole
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountCustomerRole on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountToCorrespondent
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountToCorrespondent on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AnticipatoryProfile
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AnticipatoryProfile on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh CustomerToCustomerRelationship
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CustomerToCustomerRelationship on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountEmailAddress
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountEmailAddress on $(date +'%A %d %b %Y %X')" >> "$filename"
fi
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountPhone
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountPhone on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh AccountGroupMember
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh AccountGroupMember on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/ingestion_manager/scripts/runDP.sh ChangeLog
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/ingestion_manager/scripts/runDP.sh ChangeLog on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/ingestion_manager/scripts/runDL.sh ChangeLog
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/ingestion_manager/scripts/runDL.sh ChangeLog on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh CurrencyTransaction
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh CurrencyTransaction on $(date +'%A %d %b %Y %X')" >> "$filename"
fi




TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh BranchCTRConductor
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh BranchCTRConductor on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh BranchCTRTransaction
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh BranchCTRTransaction on $(date +'%A %d %b %Y %X')" >> "$filename"
fi



TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/bdf/scripts/execute.sh BranchCTRSummary
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/bdf/scripts/execute.sh BranchCTRSummary on $(date +'%A %d %b %Y %X')" >> "$filename"
fi








#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then

echo '' >> "$filename"
echo '##### POST LOAD JOBS #####' >> "$filename"


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/ingestion_manager/scripts/runUtility.sh AccountChangeLogSummary
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/ingestion_manager/scripts/runUtility.sh AccountChangeLogSummary on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/ingestion_manager/scripts/runDL.sh AccountChangeLogSummary
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/ingestion_manager/scripts/runDL.sh AccountChangeLogSummary on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/ingestion_manager/scripts/runUtility.sh CustomerChangeLogSummary
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/ingestion_manager/scripts/runDL.sh CustomerChangeLogSummary on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$MANTAS_HOME/ingestion_manager/scripts/runDL.sh CustomerChangeLogSummary
echo "Task No.$TASK_COUNT Executed MANTAS_HOME/ingestion_manager/scripts/runDL.sh CustomerChangeLogSummary on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/analyze_business.sh DLY_POST_LOAD
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_business.sh DLY_POST_LOAD on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS_HOME/bin/analyze_business.sh DLY_POST_LOAD on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/analyze_market.sh DLY_POST_LOAD
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_market.sh DLY_POST_LOAD on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS_HOME/bin/analyze_market.sh DLY_POST_LOAD on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then

echo '' >> "$filename"
echo '##### REFRESH TMP TABLE JOBS #####' >> "$filename"

$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTADDR TMP_NETACENCU_NT_ACCTADDR_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTADDR TMP_NETACENCU_NT_ACCTADDR_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTADDR TMP_NETACENCU_NT_ACCTADDR_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTEMAIL TMP_NETACENCU_NT_ACCTEMAIL_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTEMAIL TMP_NETACENCU_NT_ACCTEMAIL_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTEMAIL TMP_NETACENCU_NT_ACCTEMAIL_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTPHONE TMP_NETACENCU_NT_ACCTPHONE_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTPHONE TMP_NETACENCU_NT_ACCTPHONE_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTPHONE TMP_NETACENCU_NT_ACCTPHONE_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTPSWRD TMP_NETACENCU_NT_ACCTPSWRD_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTPSWRD TMP_NETACENCU_NT_ACCTPSWRD_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTPSWRD TMP_NETACENCU_NT_ACCTPSWRD_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTTAXID TMP_NETACENCU_NT_ACCTTAXID_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTTAXID TMP_NETACENCU_NT_ACCTTAXID_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_ACCTTAXID TMP_NETACENCU_NT_ACCTTAXID_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_CUACADDR TMP_NETACENCU_NT_CUACADDR_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACADDR TMP_NETACENCU_NT_CUACADDR_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACADDR TMP_NETACENCU_NT_CUACADDR_VW on $(date +'%A %d %b %Y %X')" 
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_CUACEMAIL TMP_NETACENCU_NT_CUACEMAIL_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACEMAIL TMP_NETACENCU_NT_CUACEMAIL_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACEMAIL TMP_NETACENCU_NT_CUACEMAIL_VW on $(date +'%A %d %b %Y %X')" 
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_CUACPHONE TMP_NETACENCU_NT_CUACPHONE_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACPHONE TMP_NETACENCU_NT_CUACPHONE_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACPHONE TMP_NETACENCU_NT_CUACPHONE_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_CUACTAXID TMP_NETACENCU_NT_CUACTAXID_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACTAXID TMP_NETACENCU_NT_CUACTAXID_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_CUACTAXID TMP_NETACENCU_NT_CUACTAXID_VW on $(date +'%A %d %b %Y %X')" 
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_JRNL TMP_NETACENCU_NT_JRNL_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_JRNL TMP_NETACENCU_NT_JRNL_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_JRNL TMP_NETACENCU_NT_JRNL_VW on $(date +'%A %d %b %Y %X')" 
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_WIREACBENE TMP_NETACENCU_NT_WIREACBENE_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_WIREACBENE TMP_NETACENCU_NT_WIREACBENE_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_WIREACBENE TMP_NETACENCU_NT_WIREACBENE_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_WIREACORIG TMP_NETACENCU_NT_WIREACORIG_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_WIREACORIG TMP_NETACENCU_NT_WIREACORIG_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_WIREACORIG TMP_NETACENCU_NT_WIREACORIG_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/refresh_temp_table.sh TMP_NETACENCU_NT_WIRETRXN TMP_NETACENCU_NT_WIRETRXN_VW
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_WIRETRXN TMP_NETACENCU_NT_WIRETRXN_VW on $(date +'%A %d %b %Y %X')" >> "$filename"
echo "Task No.$TASK_COUNT Executed DB_TOOLS/refresh_temp_table.sh TMP_NETACENCU_NT_WIRETRXN TMP_NETACENCU_NT_WIRETRXN_VW on $(date +'%A %d %b %Y %X')"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
echo '' >> "$filename"
echo '##### BDF WORKFLOWS JOBS #####' >> "$filename"
ExecuteWorkflow $TASK_COUNT BackOfficeTransaction_OriginalTransactionReversalUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT BackOfficeTransaction_CancelledTransactionReversalCreditUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT BackOfficeTransaction_CancelledTransactionReversalDebitUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FinancialInstitution_ThomsonDataInstitutionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_ThomsonDataInstitutionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FinancialInstitution_AIIMSPopulation
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_AIIMSInstitutionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_InstitutionInsert

fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_InstitutionUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FinancialInstitution_SettlementInstruction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_SettlementInstruction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT SettlementInstruction_AccountToClientBank
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FinancialInstitution_InsuranceTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_InsuranceTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT InsuranceTransaction_AccountToClientBank
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT LoanProfile_LoanProfileStage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FinancialInstitution_FOTPSPopulation
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountToClientBank_FOTPSInstitutionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FrontOfficeTransactionParty_InstnSeqID
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FrontOfficeTransactionParty_HoldingInstnSeqID
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerAccountStage_FrontOfficeTransactionParty
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FrontOfficeTransaction_UnrelatedPartyUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_FrontOfficeTransactionPartyUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WLMProcessingLock
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Customer_KYCRiskUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_SettlementInstructionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_SettlementInstructionUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT SettlementInstruction_PhysicalDlvryAddrUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/analyze_mantas.sh ALL
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_mantas.sh ALL on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_FrontOfficeTransactioPartyStageInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_FrontOfficeTransactioPartyStageUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FrontOfficeTransactionParty_DerivedAddress
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_InsuranceTransactionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_InsuranceTransactionUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT InsuranceTransaction_InstitutionAddrUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_InsuranceTransactionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_InsuranceTransactionUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_FrontOfficeTransactionPartyInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_SettlementInstructionInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_SettlementInstructionUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBank_FrontOfficeTransactionPartyStageInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBank_FrontOfficeTransactionPartyStageUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable_WatchList
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable_WatchListInstnIDUpd
fi

#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#ExecuteWorkflow $TASK_COUNT PreviousWatchList_WatchList
#fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_WatchListNewCountries
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT LinkStaging_InsTrxnDerivedEntDerivedAdd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT LinkStaging_FrontOfficeTransactionParty
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT LinkStaging_InstructionDerivedEntDerivedAdd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT NameMatchStaging
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable_NameMatchStageInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntityLink_LinkStage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntitytoDerivedAddress_LinkStage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntitytoInternalAccount_LinkStage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddresstoInternalAccount_LinkStage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2AcctExistence
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2CBExistence
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2CustExistence
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2DAExistence
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2EEExistence
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_AcctListMembershipUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_CBListMembershipUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_CustListMembershipUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_EEListMembershipUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_EEListMembershipStatusUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_DAListMembershipUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_DAListMembershipStatusUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2SeqIdUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2IntrlIdUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Customer_WatchListStage2ListRisk
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBank_WatchListStage2EffectiveRisk
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Customer_WatchListStage2EffectiveRisk
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddress_WatchListStage2EffectiveRisk
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntity_WatchListStage2EffectiveRisk
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2SeqId
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WatchListStagingTable2_WatchListStage2IntrlId
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountListMembership_WatchListStage2Insert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountListMembership_WatchListStage2Upd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBankListMembership_WatchListStage2Insert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBankListMembership_WatchListStage2Upd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerListMembership_WatchListStage2Insert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerListMembership_WatchListStage2Upd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddressListMembership_WatchListStage2Insert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedAddressListMembership_WatchListStage2Upd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntityListMembership_WatchListStage2Insert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT DerivedEntityListMembership_WatchListStage2Upd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Account_EffectiveRiskFactorTxtUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Account_OverallEffectiveRiskUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Account_EffRiskUpdAfterWLRiskRemoval
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT Account_WatchListStage2EffectiveRisk
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT BackOfficeTransaction_EffectiveAcctivityRiskUpd
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FrontOfficeTransactionPartyRiskStage_EntityActivityRiskInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBank_JurisdictionUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBank_AcctJurisdictionReUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT FinancialInstitution_InstNameUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TransactionPartyCrossReference_BackOfficeTransaction
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CashTransaction_FrontOfficeTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT MonetaryInstrumentTransaction_FrontOfficeTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TransactionPartyCrossReference_FrontOfficeTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WireTransaction_FrontOfficeTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WireTransactionInstitutionLeg_FrontOfficeTransaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CashTransaction_FrontOfficeTransactionRevAdj
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT MonetaryInstrumentTransaction_FrontOfficeTransactionRevAdj
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WireTransaction_FrontOfficeTransactionRevAdj
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TrustedPair_StatusEXPUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TrustedPairMember_AcctExtEntEffecRiskUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TrustedPair_StatusRRCInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TrustedPair_StatusRRCUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT ApprovalActionsAudit_TrustedPair
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT TrustedPairMember_StatusRRCInsert
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT BackOfficeTransaction_TrustedFlagsUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT InsuranceTransaction_TrustedFlagsUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT MonetaryInstrumentTransaction_TrustedFlagsUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WireTransaction_TrustedFlagsUpd
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountDailyProfile-Trade
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountDailyProfile-Transaction
fi


#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#ExecuteWorkflow $TASK_COUNT AccountProfile_Trade
#fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountProfile_Transaction
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountProfile_Stage
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountProfile_Position
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountProfile_Balance
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerDailyProfile_BOT
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerDailyProfile_FOTPS
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerDailyProfile_DEAL
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerDailyProfile_INST
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CustomerProfile
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBankProfile
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountATMDailyProfile
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT ChangeLog_AcctProfileInactivity
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT AccountPeerGroupMonthlyTransactionProfile
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT CorrespondentBankPeerGroupTransactionProfile
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
ExecuteWorkflow $TASK_COUNT WLMProcessingUnlock
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
if [ $IS_FirstDate == "Y" ]; then
SQL_FILE=/data/DI_SCRIPTS/HRJ_Branches_DNFBP.sql
sqlplus -s ${CONNT} <<EOF
  @${SQL_FILE}
EOF
echo "Task No.$TASK_COUNT Executed HRJ_Branches_DNFBP job $(date +'%A %d %b %Y %X')" >> "$filename"
fi
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then

echo '' >> "$filename"
echo '##### RETAIL P-JOBS #####' >> "$filename"

$DETECTION_HOME/bin/start_chkdisp.sh 1 DIS
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_chkdisp.sh 1 DIS on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


# All BOP jobs


#### Daily | Weekly | Monthly Jobs ####

####################################################################################################################
####################################################################################################################
####################################################################################################################

# Daily Jobs Start
echo '' >> "$filename"
echo '##### Daily jobs #####' >> "$filename"		

#Large Reportable Transaction Daily
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 1
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 1 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

####################################################################################################################

#Single or multiple cash transactions-possible CTR Daily
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 2
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 2 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

####################################################################################################################

#Escalation In Inactive Acount Daily
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 3
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 3 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

####################################################################################################################

#High Risk Transactions_Focal High Risk Entity _Customer  Daily
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 5
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 5 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

####################################################################################################################

## Deposits Withdrawal Scenario consists of 6 jobs ###
# Deposits Withdrawal Same or Similar Amounts - Dep/Cash
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 15
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 15 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Deposits Withdrawal Same or Similar Amounts - Dep/MI
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 20
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 20 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Deposits Withdrawal Same or Similar Amounts - Dep/EFT
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 21
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 21 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Deposits Withdrawal Same or Similar Amounts - WD/Cash
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 22
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 22 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Deposits Withdrawal Same or Similar Amounts - WD/MI
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 23
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 23 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

# Deposits Withdrawal Same or Similar Amounts - WD/EFT
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 24
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 24 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi


# Daily Jobs End

####################################################################################################################
####################################################################################################################
####################################################################################################################

# Weekly Jobs Start
echo '' >> "$filename"
echo '##### Weekly Jobs #####' >> "$filename"		 

#Rapid Movement of Funds all activity (account)
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 4
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 4 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac	
fi

####################################################################################################################

#pre job of network of account scenerio
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 86
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 86 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac
fi

#Network of accounts 
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 6
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 6 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac
fi

####################################################################################################################

### Hub and Spoke scenario runs for Two Customer Types (IND, ORG/FIN) ###
# Hub and Spoke - Individual 
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 16
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 16 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac	
fi

# Hub and Spoke - FIN/ORG
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 17
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 17 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac	
fi

####################################################################################################################

# Structuring Avoidance of Reporting Thresholds - Deposit
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 14
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 14 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac	
fi

# Structuring Avoidance of Reporting Thresholds - Withdrawal
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")
$DETECTION_HOME/bin/start_mantas.sh 25
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 25 on $(date +'%A %d %b %Y %X')" >> "$filename"
;;
esac
fi

# Weekly Jobs End

####################################################################################################################
####################################################################################################################
####################################################################################################################

# Monthly Jobs Start
echo '' >> "$filename"
echo '##### Monthly Jobs #####' >> "$filename"			  

#CIB change in previous Average Activity AC
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
if [ $IS_FirstDate == "Y" ]; then
$DETECTION_HOME/bin/start_mantas.sh 7
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 7 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi
fi


#DNFBP
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
if [ $IS_FirstDate == "Y" ]; then
$DETECTION_HOME/bin/start_mantas.sh 87
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 87 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi
fi

# Monthly Jobs End

####################################################################################################################
####################################################################################################################
####################################################################################################################

##pre jobs of network of account scenerios
#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#$DETECTION_HOME/bin/start_mantas.sh 215
#echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 215 on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi
#
#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#$DETECTION_HOME/bin/start_mantas.sh 216
#echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 216 on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi
#
##Network of accounts 
#
#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#$DETECTION_HOME/bin/start_mantas.sh 6
#echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 6 on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi



####################################################################################################################
####################################################################################################################


## ADDED BY FAZEEL ## 
### afteringestionscript ##
#CONNT=mantas/mantas@10.128.106.24/ofsaa
#SQL_FILE=/data/DI_SCRIPTS/afteringestionscript.sql
#sqlplus -s ${CONNT} <<EOF
#  @${SQL_FILE}
#EOF

### Threshold Based Scenario ####
## For all regions (22 regions/ 2 jobs for every region i.e IND/ ORG) 
# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 13
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 13 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 27
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 27 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 28
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 28 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 29
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 29 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 30
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 30 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 31
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 31 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 32
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 32 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 33
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 33 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 34
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 34 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 35
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 7 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 36
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 36 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi


# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 37
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 37 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 38
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 38 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 39
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 39 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 40
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 40 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 41
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 41 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 42
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 42 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 43
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 43 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 44
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 44 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 45
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 45 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 46
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 46 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 47
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 47 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 48
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 48 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 49
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 49 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 50
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 50 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 51
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 51 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 52
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 52 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 53
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 53 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 54
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 54 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 55
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 55 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 56
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 56 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 57
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 57 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 58
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 58 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 59
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 59 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 60
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 60 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 61
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 61 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 62
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 62 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 63
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 63 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 64
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 64 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 65
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 65 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 66
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 66 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 67
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 67 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 68
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 68 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 69
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 69 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi

# TASK_COUNT=`expr $TASK_COUNT + 1`
# if [ $TASK_NO -le $TASK_COUNT ]; then
# $DETECTION_HOME/bin/start_mantas.sh 70
# echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 70 on $(date +'%A %d %b %Y %X')" >> "$filename"
# fi
### Threshold Based Scenario jobs End here ###


##########################################################################################################################
############################################################################################################


#case $DOW in
#"Fri")



#sqlplus mantas/mantas@10.170.4.81:1521/ofsaadb << EOF
#execute exclude_multi_mtchs_cstm_tlx();
#exit;
#EOF
#echo "Task No.$TASK_COUNT Executed Exclude Multiple Matches Job on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi


##### POST PROCESSING JOBS #####
echo '' >> "$filename"
echo '##### POST PROCESSING JOBS #####' >> "$filename"

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 501
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 501 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 502
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 502 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 503
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 503 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi
TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 504
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 504 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$BDF_HOME/scripts/execute.sh  AlertAssignment
echo "Task No.$TASK_COUNT Executed BDF_HOME/scripts/execute.sh AlertAssignment on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$BDF_HOME/scripts/execute.sh CaseAssignment
echo "Task No.$TASK_COUNT Executed BDF_HOME/scripts/execute.sh CaseAssignment on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 506
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 506 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/start_mantas.sh 507
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 507 on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/run_highlights.ksh
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_highlights.ksh on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/run_augment_trade_blotter.sh
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_augment_trade_blotter.sh on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#$DETECTION_HOME/bin/start_mantas.sh 508
#echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/start_mantas.sh 508 on $(date +'%A %d %b %Y %X')" >> "$filename"
#fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/flag_duplicate_alerts.sh
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/flag_duplicate_alerts.sh on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/run_hdc.ksh
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_hdc.ksh on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/upd_kdd_review_fin.sh
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/upd_kdd_review_fin.sh on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/analyze_business.sh DLY_PRE_HDC
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_business.sh DLY_PRE_HDC on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/analyze_business.sh DLY_POST_HDC
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_business.sh DLY_POST_HDC on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

$DB_TOOLS_HOME/bin/analyze_business.sh ALL
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_business.sh ALL on $(date +'%A %d %b %Y %X')" >> "$filename"


# Run every 1st Business Day of the month

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $IS_FirstDate in
"Y")

echo '' >> "$filename"
echo "##### 1st Business Day Of The Month Activity #####" >> "$filename"
$DB_TOOLS_HOME/bin/run_report_client.ksh
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/run_report_client.ksh on $(date +'%A %d %b %Y %X')" >> "$filename"	 
;;
esac
fi


TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DETECTION_HOME/bin/stop_chkdisp.sh DIS
echo "Task No.$TASK_COUNT Executed DETECTION_HOME/bin/stop_chkdisp.sh DIS on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
$DB_TOOLS_HOME/bin/end_mantas_batch.sh DLY
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/end_mantas_batch.sh DLY on $(date +'%A %d %b %Y %X')" >> "$filename"
fi

TASK_COUNT=`expr $TASK_COUNT + 1`
if [ $TASK_NO -le $TASK_COUNT ]; then
case $DOW in
"Fri")

echo '' >> "$filename"
echo "##### Friday Weekly Activity #####" >> "$filename"
$DB_TOOLS_HOME/bin/analyze_mantas.sh ALL
echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_mantas.sh ALL" >> "$filename"
;;
esac
fi

#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#case $DOW in
#"Fri")
#$DB_TOOLS_HOME/bin/analyze_business.sh ALL
#echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_business.sh ALL on $(date +'%A %d %b %Y %X')" >> "$filename"
#
#;;
#esac
#fi
#
#TASK_COUNT=`expr $TASK_COUNT + 1`
#if [ $TASK_NO -le $TASK_COUNT ]; then
#case $DOW in
#"Fri")
#$DB_TOOLS_HOME/bin/analyze_market.sh ALL
#echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/analyze_market.sh ALL on $(date +'%A %d %b %Y %X')" >> "$filename"
#;;
#esac
#fi

 # TASK_COUNT=`expr $TASK_COUNT + 1`
 # if [ $TASK_NO -le $TASK_COUNT ]; then
 # $DB_TOOLS_HOME/bin/end_mantas_batch.sh DLY
 # echo "Task No.$TASK_COUNT Executed DB_TOOLS_HOME/bin/end_mantas_batch.sh DLY on $(date +'%A %d %b %Y %X')" >> "$filename"
 # fi


	 echo '' >> "$filename"
	 echo "########################## Ending AML data ingestion for MIS Date $MISDATE ##########################"
	 echo "########################## Ending AML data ingestion for MIS Date $MISDATE ##########################" >> "$filename"
	 echo '' 

