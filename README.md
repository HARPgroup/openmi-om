# openmi-om
A lightweight implementation of the OpenMI framework for building Object-oriented Meta-models.

INSTALLATION
Currently installation is from tar.gz only.  Use the following command:
```
install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9102.tar.gz', repos = NULL, type="source")
```

BUILDING
```
# From R command prompt
library('roxygen2')
setwd('/usr/local/home/git/openmi-om/R/openmi.om')
roxygenize()

cd R
R CMD build openmi.om

```
