z <- rlang::expr(y <- x * 10)
# this fails if x is not defined first
rlang::parse_expr(z)

z <- quote(y <- x * 10)
quote(z)

eq = expression("whtf123_reg_mgd - whtf_reg_mgd")
data = list(x = 10, y = 20)



for (i in names(obj$components)) {
  message(paste(i,"$update()"))
  obj$components[[i]]$update()
}

flowby <- obj$components$flowby
flowby$update()
flowby$evaluate()
flowby$defaultvalue

# why does the evaluate() on flowby return the whole function core-dump?
tryCatch(
  {
    s_envir <- c(flowby$data, flowby$arithmetic_operators)
    value <- eval(parse(text=flowby$equation), envir=s_envir)
    value <-eval(flowby$eq, envir=s_envir)
  },
  error=function(cond) {
    # if no. of errors not exceeded,
    self$numnull <- self$numnull + 1
    if (self$numnull <= 5) {
      message(paste("Could not evaluate"))
      message(cond)
    }
    # Choose a return value in case of error
    value <- self$defaultvalue
  }
)

# I control these
arithmetic_operators <- Map(
  get, c(
    "(", "+", "-", "/", "*", "^",
    "sqrt", "log", "log10", "log2", "exp", "log1p"
  )
)
data <- list(a=1, b=2, release = 5)
safe_envir <- c(data, arithmetic_operators)

eq_str_nums = "1.0 + 5.0"
eval(parse(text=eq_str_nums), envir=safe_envir)
eq_str_ab_vars = "a + b"
eval(parse(text=eq_str_ab_vars), envir=safe_envir)
eq_str = "release + 5.0"
eval(parse(text=eq_str), envir=safe_envir)
eq_str_abr_vars = "a + b + release"
eval(parse(text=eq_str_abr_vars), envir=safe_envir)
eq_str_r_vars = "release"
eval(parse(text=eq_str_r_vars), envir=safe_envir)
# this fails because the dummy var is not found
eq_str_d_vars = "dummy"
eval(parse(text=eq_str_d_vars), envir=safe_envir)
# this fails because the dummy var is not found
eq_str_rf_vars = "read.csv"
eval(parse(text=eq_str_rf_vars), envir=safe_envir)

eq = expression("release + 5.0")
substitute(eq,safe_envir)
eq = substitute(eq_str,safe_envir)
eval(eq_str, envir=safe_envir)


safe_f <- c(
  getGroupMembers("Math"),
  getGroupMembers("Arith"),
  getGroupMembers("Compare"),
  "<-", "{", "("
)

safe_env <- new.env(parent = emptyenv())

for (f in safe_f) {
  safe_env[[f]] <- get(f, "package:base")
}

safe_eval <- function(x) {
  eval(substitute(x), env = safe_env)
}

safe_eval(eq)

