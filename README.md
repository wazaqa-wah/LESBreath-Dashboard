# LESBreath-Dashboard
## Introduction
This project is based upon the request of LES Breath (Lower East Side), a community committee within the nonprofit East River Park Action. To monitor the air quality of the East River Park due to city construction, their members installed Purple Air sensors in 4 different places around the park and started gathering data. They reached out to BetaNYC for us to build a dashboard based on the data collected by the sensors and I took on the project. 
The dashboard is unfinished mainly due to the some issue with accessing data through Purple Air API since they were working on updating the community guideline for getting historical data, which is what we want.
## Goals
- This project was aimed to help LES Breathe to develop a tool to
- Get real time air quality data from the Purple Air monitors they set up
- Allow people to compare historical air quality data by different time period (daily, weekly, monthly, yearly)
- Provide air quality information/knowledge to the community (how to interpret air quality? what factors affect air quality? what are recommendations for different air quality)
## Decisions
Some decisions are made on my end after 2 initial meetings with the LES Breath team.
Moke up to the dashboard. (self-taught Figma, not interactive):  https://www.figma.com/file/HGHVFygIlOnzktZ0GjpGwi/LES-Breath
- The aim for the dashboard is to be as simple as possible. There are comments on the mock up that explains the choices that I made
- The side bar is consist of **dashboard**, which displays real-time information, **time machine**, which allows people to go back in time and compare different parameters of one censor through different time period, and we also decided to add an **about** page, so we can explain our methodology, help people understand how to read graphs and extract information, and provide the GitHub link to the code
- The dashboard page displays the 4 censors and the corresponding **real-time** parameters that we are looking atL AQI, PM 2.5, Humidity and Temperature. When click on dashboard on the sidebar, people can also select a specific sensor, and they can see the trend of the data being reported for the last 24 hours till now.
- When click on the Time Machine tab, several selection will show up: select sensor, select time to compare (day, week, month, year), and select date on the calendar. People can only compare data from one censor, and they can select up to 3 different time to compare. For example, you can only compare sensor 1’s data from June, July, and August; or sensor 2 for June 3, June, 7, and June 9. You can’t compare across sensors.
- The about page should be an effort between Beta NYC, LES and the health department. We hope that the health department can provide us with some existing material on informing people about air quality, and Beta NYC will provide methodology, and LES can write up a part about their own organizations.
## Coding Decisions
- Use R Shiny to build dashboard
- Comments will be made in the the Git Hub document as well as in the code itself
- Graphing PM 2.5
    - The uploaded file is what it looks like. The grey area was the Max and Min, and the red is the average. But we decided to use the 25% and the 75% quartiles to shade the grey area since the max and min values are not very representative. This makes the graphs looks better and more scientific, but it does pose challenge for how do we explain this to our audience. I think if we explain it well it will help people to understand air quality more
- Constructing API
    - I created a group with all 4 censors that LES Breathe want to manage in it, all of that information is at the top
    - 4 cate
    - This is the calling URL we are using:
        - we are using Calling Member History: [https://api.purpleair.com/#api-groups-get-member-history](https://api.purpleair.com/#api-groups-get-member-history)
        - example: [https://api.purpleair.com/v1/groups/1211/members/56213/history/csv?start_timestamp=1659972543&end_timestamp=1660058943&fields=pm2.5_atm,humidity,temperature](https://api.purpleair.com/v1/groups/1211/members/56213/history/csv?start_timestamp=1659972543&end_timestamp=1660058943&fields=pm2.5_atm,humidity,temperature)
    - Here’s what data we are pulling for different historical time period:
        - The Purple Air has different codes for the averages of the data that they are collecting, as well as the time span of the data you can get for each average
            - Real-time: 2 days
            - 10 Minute : 3 days
            - 30 minute: 7 days
            - 1 hr: 14 days
            - 6hr: 90 days
            - 1 day: 1 year
        - This is what we choose for our time span selection:
            - weekly <- "30" #average of 30 minutes, 
            monthly <- "10080" #average of a week
            yearly <- "44640" #average of a month
                
                Daily we use the default, which is the average of 10 minutes
