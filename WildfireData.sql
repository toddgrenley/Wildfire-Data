
-- The Wildfire data comes broken into 2 sections in order to cover the 3 years of data I requested (most is in the first file), so a simple union should give us
-- one complete timeline of the data. But the first file also has an extra column which appears to have little meaning, so we'll have to remove that first. We'll also
-- create a View out of it so we can further query it without having to repeat the union. 'MODIS' is a reference to the instrument used to take the readings. 

ALTER TABLE [Wildfire Database]..fire_archive_MC61_323979
DROP COLUMN type

CREATE VIEW WildfireDataMODIS
AS
SELECT *
FROM [Wildfire Database]..fire_archive_MC61_323979
UNION
SELECT *
FROM [Wildfire Database]..fire_nrt_MC61_323979

-- Let's test it out. SQL Server automatically orders it by latitude, the first column, so we'll order by the date and time the readings were taken, the way the data 
-- orginally was so we get a sequential view.

SELECT *
FROM WildfireDataMODIS
ORDER BY acq_date, acq_time



-- The Brightness readings will be used later to create a fire map, so for now let's explore this data to see what else is interesting. There appears to be 2 different
-- satellites, Aqua and Terra, that take the readings, as well as day vs. night sampling times, so let's see which are most active.

SELECT satellite, COUNT(satellite)
FROM WildfireDataMODIS
GROUP BY satellite

SELECT daynight, COUNT(daynight)
FROM WildfireDataMODIS
GROUP BY daynight

-- The satellites take roughly the same number of readings, but there are three times as many daytime readings as there are night. My hypothesis would have been more
-- at night by way of greater apparent contrast with the surrounding terrain, but this likely makes little difference to the MODIS instrument. Let's see if there are
-- any differences in average brightness for these variations as well.

SELECT satellite, AVG(brightness)
FROM WildfireDataMODIS
GROUP BY satellite

SELECT daynight, AVG(brightness)
FROM WildfireDataMODIS
GROUP BY daynight

-- There are not, save for slightly more brightness during day readings, which may be explained simply by more natural heat present when the sun is out. But there is
-- actually a slightly larger variation between satellites (approx. 1%), so this may be coincidence. Let's break this down further so we can get a better idea of what
-- might be causing the differences in readings.

SELECT satellite, daynight, COUNT(satellite) AS Readings, AVG(brightness) AS Brightness
FROM WildfireDataMODIS
GROUP BY satellite, daynight

-- Aqua's day readings are the hottest, but Terra's night readings are slightly hotter than its days, so this suggests daytime is not a factor. But this brings me to 
-- my next point. MODIS, which stands for Moderate Resolution Imaging Spectroradiometer, is not the only instrument used to take thermal readings of wildfires. MODIS 
-- has been in use by NASA's Earth Observatory for over 20 years now, but a newer instrument, known as VIIRS (Visible Infrared Imaging Radiometer Suite), has been 
-- deployed and has a higher resolution thermal band to take measurements with. Thus, it is more sensitive and can detect smaller fires. This will give us a comparison 
-- to work with, so let's bring in the VIIRS data as well. Same as before, we'll need to remove the extra column and create a View for further querying.

ALTER TABLE [Wildfire Database]..fire_archive_SVC2_323981
DROP COLUMN type

CREATE VIEW WildfireDataVIIRS
AS
SELECT *
FROM [Wildfire Database]..fire_archive_SVC2_323981
UNION
SELECT *
FROM [Wildfire Database]..fire_nrt_SVC2_323981

-- Let's test it out. Same as MODIS, we'll order by acquistion time to get a sequential view.

SELECT *
FROM WildfireDataVIIRS
ORDER BY acq_date, acq_time



-- All of the VIIRS readings are taken from a single satellite, so no comparisons can be done there, but there are still day vs. night readings.

SELECT daynight, COUNT(daynight)
FROM WildfireDataVIIRS
GROUP BY daynight

-- VIIRS takes more readings at night, which is in line with my earlier hypothesis. Let's check average brightness as well.

SELECT daynight, AVG(brightness)
FROM WildfireDataVIIRS
GROUP BY daynight

-- Day readings are considerably higher for VIIRS, so this may speak to the natural heat phenomenon during the day, which also lines up with my hypothesis. It's hard 
-- to say for sure, as this could be pure coincidence, but as suspected the greater sensitivity of the VIIRS has brought in more data that has aligned with natural
-- suspicions. It may be that the older MODIS is simply not sensitive enough to grasp the smaller changes in temperature.