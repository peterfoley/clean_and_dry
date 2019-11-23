# functions for working with configuration

strict_config <- function(value, ...) {
  res <- config::get(value, ...)
  if(is.null(res)) {
    stop(paste0("no config value found for: ", value))
  }
  res
}
