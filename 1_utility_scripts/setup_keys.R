# set up garmin password in keyring

source("utils/config.R")

keyring::key_set_with_value(
  strict_config("garmin_connect_keyring_service"),
  username = strict_config("garmin_connect_username"),
  password = rstudioapi::askForPassword("Garmin Connect password")
)
