# Computer and Broadband Access for the Labor Force - Interactive Map

This shiny app displays a county-level map of the United States, investigating internet access and personal computer access for the labor market. This is a useful application because it visualizes where computer access and broadband internet access are lowest for workers. 

Data for this map comes form the Census Bureau's API for the American Community Survey (ACS). The ACS is a large scale demogrpahic survey across the U.S. The API requires a key. I utilized the detailed table for the 2021 ACS here: api.census.gov/data/2021/acs/acs1?get=NAME,group(B01001)&for=us:1&key=YOUR_KEY_GOES_HERE. The key is stored in an ignored json file. 

The app is broken down into four tabs- the map, a datatable, a bar chart, and a scatter plot. 

The map is constructed using leaflet. It has three layers, and each layer can be plotted onto the map using leaflet proxy so the underlying map does not reload each time. The user controls this option with three radio buttons. 

The datatable presents the user with county-by-county observations for the size of the labor market, the number of individuals with computers and broadband access, those with jsut dialup access, those without computers, and standard information such as unemployment figures. 

The bar chart was created using plotly for interactivity. It allows the user to view the counties with the most dial-up internet connections. Mobile County Alabama has the highest number of workers with dial-up connections, for example. 

The scatter plot was also created using plotly. It allows the user to view which counties have the largest share of unemployed persons scattered against the largest share of unemployed persons without a personal computer. 

Users can filter these charts using the input commands on the side bar which appear as a slider. Users can also download the data as a csv file using the downloadHandler. 

The application is hosted at: https://blwallac.shinyapps.io/final-project-blwallac/
