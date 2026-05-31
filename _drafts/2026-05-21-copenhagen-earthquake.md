---
layout: post
title: "Reading an Earthquake with ObsPy"
tags: [project, data-science]
description: "There was a magnitude 3.5 earthquake near Copenhagen on May 20, 2026. I pulled the raw seismic data from GEOFON and learned how to read seismograms using ObsPy."
---

## The Earthquake

On May 20th, 2026, at 14:14 UTC, there was a magnitude 3.5 earthquake about 37 km south of Copenhagen, near the town of Bjæverskov. I didn't feel it (I was on the metro, which does a good job of feeling like an earthquake), so instead, I wanted to experience the data.

Denmark has a network of broadband seismometers operated by [GEUS](https://www.geus.dk/) (the Geological Survey of Denmark and Greenland). The data is publicly available through [GEOFON](https://geofon.gfz-potsdam.de/), and there's a Python library called [ObsPy](https://docs.obspy.org/) that can fetch and process it. 

I spent the evening reading about seismometers and how to make the different plots.

## The Dayplot

The first plot I learned about is the dayplot, which shows seismographic data over time. It's read from left-to-right and top-to-bottom. You can imagine lining up each row end-to-end, and being left with a very long time series. 

Here, you can see 12 hours of the vertical component data ("HHZ") from station DK.LLD (Lille Linde, on Lolland):

![Dayplot of DK.LLD.HHZ on 2026-05-20](/assets/images/cph_earthquake/dayplot.png)

The earthquake at 14:14 is immediately obvious. I read about the other small blips throughout the day potentially being "cultural noise": trucks, wind, machinery, even military or mining activity. However, these plots are also often used to see "preshocks" and aftershocks.

## Two Body Waves

When an earthquake happens, it sends out two types of body waves, which travel through the earth's crust (as opposed to surface waves, which, as the name suggests, travel along the earth's surface).

P-waves (primary) are compressional waves which travel at about 6 km/s through the upper crust. They oscillate along the same axis the wave propagates, like a sound wave.  

S-waves (secondary) are "shear" waves, moving more like a ripple through a rope. They move slower at about 3.5 km/s and carry more energy.

Both waves leave the epicenter at the same time. Because the P-wave is faster, it arrives first, followed by the S wave some time later. The further you are from the source, the bigger the gap between them.


![Three-component waveform at DK.COP](/assets/images/cph_earthquake/waveform_3c.png)

This is the three-axis waveform at station DK.COP (Copenhagen), zoomed in on the event. The top trace is the vertical component (HHZ, like we saw in the dayplot), and the bottom two are the horizontals (HHN, HHE). 

You can see the P-wave arrive at 14:14:42 as a small wiggle, and then the S-wave hits at 14:14:47 with much larger amplitude, but _before_ the earthquake hits it's highest peak (caused by surface waves). 

That ~5 second S-P gap tells us how far away the earthquake was. Both waves travel the same path but at different speeds, so:

```
distance = (S-P time) / (1/Vs - 1/Vp)
distance = 5 / (1/3.5 - 1/6.0)
distance = 42 km
```

This agrees with the epicenter being reported at at 55.45°N, 12.02°E, about 42.66 kilometers SW from the COP station.

You can see this principle even more clearly in the plot of the same event recorded at stations across Denmark and northern Germany, arranged by distance from the epicenter:

![Section plot showing wave propagation](/assets/images/cph_earthquake/section.png)

The x-axis is distance in kilometers, the y-axis is time in seconds after the origin. At each station, you can see the P-wave arrive first, followed by the larger S-wave. 

As you move further from the epicenter, the gap between them grows: at LLD (18 km away from the epicenter) they're almost on top of each other, at COP (42 km) there's a few seconds between them, and by the time you get out to RGN (131 km) or RUE (351 km), the separation is substantial.

You can also watch the wavefront propagate outward. The diagonal line traced by the first arrivals (not shown here) gives you the wave velocity directly.

This is all a generalization, however. As you can see, the P-wave arrives at BSD (Bornholm, ~<TODO> km) before MUD (Stoholm, ~<TODO> km). However, the S-wave appears to arrive in MUD _before_ BSD! This is due to the 

## ObsPy

The code for all of this is surprisingly short. ObsPy has an FDSN client that talks to GEOFON's web service, so fetching data is just:

```python
from obspy import UTCDateTime
from obspy.clients.fdsn import Client

client = Client(base_url="http://geofon.gfz-potsdam.de")
st = client.get_waveforms("DK", "COP", "*", "HH?",
    UTCDateTime("2026-05-20T14:13:30"),
    UTCDateTime("2026-05-20T14:18:00"))
```

That gives you an ObsPy `Stream` object containing traces for each channel. From there, standard signal processing is all built in:

```python
st.detrend("demean")
st.detrend("linear")
st.taper(max_percentage=0.05)
st.filter("bandpass", freqmin=2, freqmax=8, zerophase=True)
st.plot()
```

For the section plot, I used `obspy.geodetics.gps2dist_azimuth` to compute the distance from the epicenter to each station, set that as a trace header, and then called `st.plot(type="section")`. The library does the layout.

The data format is miniSEED, which is the standard in seismology. ObsPy reads it natively. I cached the downloads locally so I wasn't hitting the server repeatedly while iterating on plots.

## What I Learned

Seismology felt inaccessible to me before this. It isn't. The data is public, the tools are open source, and the basic physics (two waves, different speeds, measure the gap) is something you can verify yourself with a few lines of Python.

I'm not going to pretend I can locate an earthquake better than USGS. But I can pull the same raw data they use, see the same arrivals, and understand why the math works.

Data source: [GEOFON](https://geofon.gfz-potsdam.de/) (GFZ Potsdam). Station networks: DK (GEUS, Denmark), GE (GEOFON).
