#load library
library(webshot)
library(googleAnalyticsR)
library(lubridate)
library(ggplot2)
library(png)
library(grid)
ga_auth()

domain <- "https://www.google.com"
pagePath <- "/landingpage.html"
url <- paste(domain,pagePath, sep= "")
element <- ".main"

# full page
webshot(url, "full_page.png")

#only viewport
#webshot(url, "viewport.png", cliprect = "viewport")


# specific element on page
#webshot(url, "element.png", selector = element)

# Zoom in on specific element
#webshot(url, "element-zoom.png", selector = element, zoom = 2)

# This is where you add the Google Analytics View ID
viewId <- "121212321"

#colors for the barchart visualisation
dlPalette <- c("#009FDA", "#9FA6AA", "#5E6A71", "#003C52")

#set dates today, yesterday, last month and for document purposes
dateToday <- as.Date(format(Sys.time(), "%Y-%m-%d"))
dateYesterday <- dateToday - days(1)
dateStart <- dateToday - days(21)


#filter pagelevel
df <- dim_filter("pagePath","EXACT",pagePath)
df2 <- dim_filter("eventCategory","EXACT","scrolling")
fc2 <- filter_clause_ga4(list(df,df2), operator = "AND")

pageEvents <- google_analytics_4(viewId, 
                                 date_range = c(dateStart, dateYesterday),
                                 dimensions=c("eventCategory", "eventLabel"), 
                                 metrics = c("uniqueEvents"),
                                 dim_filters = fc2,
                                 anti_sample = TRUE)


pageEvents$eventLabel <- c(0,100,25,50,75)
pageEvents <- pageEvents[with(pageEvents, order(eventLabel)), ]

# Calculate diferences between areas on the page
pageEvents$netScroll<-abs(c(diff(pageEvents$uniqueEvents),pageEvents$uniqueEvents[5]))
pageEvents$perc <- round(pageEvents$netScroll / sum(pageEvents$netScroll) * 100,2)

# Image that will be the background of our viz
img <- readPNG("full_page.png") 

# Finding the scale and using that to scale the plot on ggsave
pngInfo <- readPNG("full_page.png", info = TRUE)
pngSize <- attr(pngInfo, "dim") 
pngHeight <- pngSize[1] / 100
pngWidth <- pngSize[2] / 100


# visualise the number of unique events
plot_scrolls <- ggplot(data = pageEvents,aes(y= eventLabel, x = "x", label = uniqueEvents, color = "red")) +
  annotation_custom(rasterGrob(img, 
                               width = unit(1,"npc"), 
                               height = unit(1,"npc")), 
                               -Inf, Inf, -Inf, Inf) +
  theme(axis.text.x=element_blank())+
  scale_y_reverse()+
  geom_text(size = 30) +
  geom_hline(yintercept= c(0,25,50,75,100), color = "red", alpha = 0.8, linetype = 2, size = 2.5) + 
  xlab(NULL)+
  ylab("% scrolled of page")+
  theme(legend.position="none",text = element_text(size=50))

# visualise sam plt, but with netto scrolls
plot_netto_scrolls <- ggplot(data = pageEvents,aes(y= eventLabel, x = "x", label = netScroll, color = "red")) +
  annotation_custom(rasterGrob(img, 
                               width = unit(1,"npc"), 
                               height = unit(1,"npc")), 
                               -Inf, Inf, -Inf, Inf) +
  theme(axis.text.x=element_blank())+
  scale_y_reverse()+
  geom_text(size = 30) +
  geom_hline(yintercept= c(0,25,50,75,100), color = "red", alpha = 0.8, linetype = 2, size = 2.5) + 
  xlab(NULL)+
  ylab("% scrolled of page - dropoff point")+
  theme(legend.position="none",text = element_text(size=50))

# Visualise the maximum level of scroll by a user in a barchart
barchart_scrolls <- ggplot(data = pageEvents, aes(y= netScroll, x = eventCategory, fill = eventLabel)) +
  geom_bar(position = "fill",stat="identity")  +
  scale_y_reverse()+
  xlab("")+
  ylab("% scrolled of page") +
  theme(legend.title = element_blank())

#save the images to png
ggsave("plot_scrolls.png", plot_scrolls, width = pngWidth, height = pngHeight)
ggsave("plot_netto_scrolls.png", plot_netto_scrolls, width = pngWidth, height = pngHeight)
ggsave("barchart_scrolls.png", barchart_scrolls)

