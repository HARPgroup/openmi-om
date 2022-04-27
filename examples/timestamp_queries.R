# Roanoke Dan cia tables for model debugging
# where is the extra water coming from in 2030 scenario?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools")
library("openmi.om")

# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh:81"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private");
source(paste(basepath,'config.R',sep='/'))


runid = 6015
dat <- om_get_rundata(247415, runid, site = omsite)
dat_smd <- dat[960:980]
dat_smd <- dat
dat_smd$timestamp <- as.integer(index(dat_smd))
beg<- as.POSIXct( format(min(index(dat_smd)), "%Y-%m-%d %H:%M", tz="EST5EDT"))
bend<- as.POSIXct( format(max(index(dat_smd)), "%Y-%m-%d %H:%M", tz="EST5EDT"))
dat_smd <- as.data.frame(dat_smd)
ts = 12*60*60
#*************************************************
# tbase would be produced by the timer object
# and shared with all children that wish to produce a
# matching timeseries
tbase <- seq(as.integer(beg), as.integer(bend), by=ts)
tbase <-  as.data.frame(tbase)
names(tbase) <- c('timestamp')
#*************************************************


# all at the same time, which can take forever
# keep this just for time comparison
tsmatrix <- sqldf(
  "
  select a.timestamp as t_start, a.timestamp + $ts as t_end,
    min(b.timestamp) as first_inner,
    max(b.timestamp) as last_inner,
    max(c.timestamp) as previous_outer,
    min(d.timestamp) as next_outer
  from tbase as a
  left outer join dat_smd as b
  on (
    b.timestamp >= a.timestamp
    and b.timestamp < (a.timestamp + $ts)
  )
  left outer join dat_smd as c
  on (
    c.timestamp < a.timestamp
  )
  left outer join dat_smd as d
  on (
    d.timestamp > a.timestamp
  )
  group by a.timestamp
  "
)


# one at a time

#*************************************************
# matrix 1 captures all events between the given index timestamp
tsmatrix1 <- fn$sqldf(
  "
  select a.timestamp as t_start, a.timestamp + $ts as t_end,
    min(b.timestamp) as first_inner,
    max(b.timestamp) as last_inner
  from tbase as a
  left outer join dat_smd as b
  on (
    b.timestamp >= a.timestamp
    and b.timestamp < (a.timestamp + $ts)
  )
  group by a.timestamp
  "
)
#*************************************************


#*************************************************
# matrix 2 captures the previous outer timestamp
tsmatrix2 <- sqldf(
  "
  select a.t_start, a.t_end,
    a.first_inner,
    a.last_inner,
    max(c.timestamp) as previous_outer
  from tsmatrix1 as a
  left outer join dat_smd as c
  on (
    c.timestamp < a.t_start
  )
  group by a.t_start
  "
)
#*************************************************


#*************************************************
# matrix 3 captures the next outer timestamp
tsmatrix3 <- sqldf(
  "
  select a.t_start, a.t_end,
    a.first_inner,
    a.last_inner,
    a.previous_outer,
    min(d.timestamp) as next_outer
  from tsmatrix2 as a
  left outer join dat_smd as d
  on (
    d.timestamp > a.t_start
  )
  group by a.t_start
  "
)
#*************************************************

dat_smd_Q <- sqldf("select timestamp, Qlocal from dat_smd")


tsvalues_in <- sqldf(
  "select a.t_start, a.t_end,
      a.first_inner, a.last_inner,
      a.previous_outer, a.next_outer,
      avg(b.Qlocal) as inner_mean,
    count(b.Qlocal) as inner_count
    from tsmatrix3 as a
    left outer join dat_smd as b
    on (
      a.first_inner <= b.timestamp
      and a.last_inner >= b.timestamp
    )
    group by a.t_start, a.t_end, a.first_inner, a.last_inner,
      a.previous_outer, a.next_outer
  "
)

# how to interpolate when the distance between prev and next is not uniform?
# we need to know starting and ending values, which could be accomplished
# by joining the value table twice, once to prev ts and once to next ts
tsvalues_out <- sqldf(
  "select a.t_start, a.t_end,
      a.previous_outer, a.next_outer,
      (b.Qlocal + c.Qlocal) / 2.0 as outer_mean,
      count(b.Qlocal) as outer_count,
      (a.next_outer - a.t_start )
        / (a.next_outer - a.previous_outer) as int_frac,
      b.Qlocal + (
        (c.Qlocal - b.Qlocal) *
        (a.next_outer - a.t_start )
        / (a.next_outer - a.previous_outer)
      ) as int_value
    from tsvalues_in as a
    left outer join dat_smd as b
    on (
      a.previous_outer = b.timestamp
    )
    left outer join dat_smd as c
    on (
      a.next_outer = c.timestamp
    )
    where a.inner_count = 0
    group by a.t_start, a.t_end, a.first_inner, a.last_inner,
      a.previous_outer, a.next_outer
  "
)

# join the final result together, using inner when available
# and outer interpolation when not
# @todo:
#  - allow prev, next value for outer
#  - allow min, max, median for inner
tsvalues <- sqldf(
  "select a.t_start as timestamp,
     CASE
       WHEN a.inner_count = 0 THEN b.int_value
       ELSE a.inner_mean
     END as tsvalue
   from tsvalues_in as a
   left outer join tsvalues_out as b
   on (
     a.t_start = b.t_start
   )
   order by a.t_start
  "
)

index(tsvalues) <- tsvalues$timestamp
# timestamps: first_inner, last_inner, first_outer, last_outer
# now, we do summaries
# if first_inner is and last_inner are non-null
# we have matches inside the timestep so we do
  # a mean value for those and we're done (or whatever the selected stat is)
  # could apply other logics to work better for extra large timesteps
  # by considering the last_inner and last_outer values, but have not done that prior

# remaining null values interpolate based on selected first_outer, last_outer
  # prev (use first_outer), next (use last_outer, mean (do a mean value)
