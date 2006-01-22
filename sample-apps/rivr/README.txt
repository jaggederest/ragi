INSTALLING RIVR

1) Edit app/config.rb to put in your database connection details, create a blank database 
as named in your connection details. Ensure that the user name and password you specified
can connect to that database.

2) Use db/schema.rb or db/schema.mysql to create your database schema

3) Configure Asterisk to listen for /rivr and for /setup on different extensions.

	exten => 100,1,NoOp(Incoming call for RIVR)
	exten => 100,2,deadagi(agi://127.0.0.1/rivr)
	exten => 101,1,NoOp(Incoming call for RIVR Administration)
	exten => 101,2,deadagi(agi://127.0.0.1/setup)
	
4) Launch RIVR by running

	ruby rivr.rb

5) Dial 101 (if you did it as above) to setup your sounds for each symbol as listed below.
At each beep, speak the message beside the symbol on the left. The listing below is
in order of the beeps that you will hear, one per beep.

	mobileNumber			Please enter your mobile phone number (10 digits)
	mobileNumberAgain		Please enter your mobile phone number again
	tryAgain					Please try again.
	thankYou					Thank you, and have a nice day!
	provider_1				Press 1 for xxx units, 2 for yyy units, 3 for zzz units
	provider_2				Press 1 for xxx units, 2 for yyy units, 3 for zzz units
	provider_3				Press 1 for xxx units, 2 for yyy units, 3 for zzz units
	provider_4				Press 1 for xxx units, 2 for yyy units, 3 for zzz units
	provider_1_1			provider_1 xxx units
	provider_1_2			provider_1 yyy units
	provider_1_3			provider_1 zzz units
	provider_2_1			provider_2 xxx units
	provider_2_2			provider_2 yyy units
	provider_2_3			provider_2 zzz units
	provider_3_1			provider_3 xxx units
	provider_3_2			provider_3 yyy units
	provider_3_3			provider_3 zzz units
	provider_4_1			provider_4 xxx units
	provider_4_2			provider_4 yyy units
	provider_4_3			provider_4 zzz units
	account					Please enter your bank account number followed by the '#' key on the lower right of your keypad.
	pin						Please enter your 4 digit PIN
	invalidInput			I don't understand what you meant. Good bye!
	outOfStock				The product you selected is not available now. Try again later.
	insufficientBalance	You do not have enough money in your account. Good bye.
	badCredentials			You supplied an invalid debit card number or pin number
	voucherAlreadyUsed	The last available coupon has already been taken. You have not been charged for this transaction. Good bye.
	bruteForce				You have supplied invalid information too many times. Your account has been locked.
	transactionFailed		A system error occurred. You have not been charged for this transaction.
	systemError				The service is currently unavailable. We regret any inconvenience caused.
	
6) Dial 100 to test the system. The schema supplied will work if you enter a 
mobile number of 555 xxx xxxx, a bank account of 1234567890, and a pin of 1234.
When entering your bank account number, you must follow the number with the '#'
key. The mobile number must have exactly ten digits, and the pin must have exactly
four digits. You must choose the xxx units option, because the test database doesn't
have other denominations in it ...