source('~/openmi-om/R/utils/fn.land.use.wdm.export.all.R')
source('~/openmi-om/R/utils/fn.land.use.eos.all.R')

batch.land.use <- function(land.segs, mod.scenario, start.year, end.year) {
  num.runs <- length(land.segs)
  for (i in 1:num.runs) {
    print(paste('Generating land use files for segment', i, 'of', num.segs, sep = ' '))
    land.use.wdm.export.all(land.segs[i],'/opt/model/p6/p6_gb604',mod.scenario, start.year, end.year)
    land.use.eos.all(land.segs[i], '/opt/model/p6/p6_gb604', mod.scenario, paste0('/opt/model/p6/p6_gb604/out/land/', mod.scenario, '/eos'))
  }
}