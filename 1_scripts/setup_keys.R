# set up garmin password in keyring

keyring::key_set_with_value(
  "sso.garmin.com",
  username=rstudioapi::askForPassword("Garmin Connect username/email"),
  password=rstudioapi::askForPassword("Garmin Connect password"))
