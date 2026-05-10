config = {
	"attacker_site": b"attacker.test", # attacker.test
	"legitimate_site_address": b"alice@victim.test", # From header address displayed to the end-user
	"victim_address": b"bob@victim.test", # RCPT TO and message.To header address, 
	"case_id": b"server_a1", #  You can find all case_id using -l option.

	# The following fields are optional
	"server_mode":{
		"recv_mail_server": "10.9.0.6", # If no value, espoofer will query the victim_address to get the mail server ip
		"recv_mail_server_port": 25,
		"starttls": False,
	},
	"client_mode": {
		"sending_server": ("smtp.gmail.com", 587),
		"username": b"attacker@gmail.com",
		"password": b"",
	},

	# Optional. You can leave them empty or customize the email message header or body here
	"subject_header": b"",  # Subject: Test espoofer\r\n
	"to_header": b"", # To: <alice@example.com>\r\n
	"body": b"", # Test Body.

	# Optional. Set the raw email message you want to sent. It's usually used for replay attacks
	"raw_email": b"", 
}



