# Starting app

## Serving on local network

To start app running on port `8888` on your local network, run the `startServer.R` script.

```bash
Rscript startServer.R
```

## Running locally to develop

Since periodic dumps of the `sqlite` db are in this repo, you can also run this app locally as long as you have the repo cloned. Just open it in RStudio and press the run icon or in your R console type:

```R
shiny::runApp()
```

_Keep in mind the date filtering will probably return nothing in this case because unless the database was committed within 24 hours of you running the app no results will return._
