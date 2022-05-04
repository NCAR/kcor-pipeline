# CME retraction

- [x] when sending an alert for a CME, update the CME list
- [ ] finish kcor_cme_retract.pro
- [ ] occasionally check "to retract" list with kcor_cme_find_retractions and call
      kcor_cme_retract when needed

# simulated_realtime_nowcast mode

in simulator, i.e., kcor simulate:

- [-] occasionally write the current UT date/time to a time file, i.e.,
      time_dir/OBSERVING_DATE.time.txt

in cme detection:

- [-] when writing any JSON alert, if in "simulated_realtime_nowcast" mode, check
      time_dir/OBSERVING_DATE.time.txt instead of using SYSTIME

test on:

- [-] 2017-09-04
- [-] 2017-09-09
- [x] 2017-10-10
